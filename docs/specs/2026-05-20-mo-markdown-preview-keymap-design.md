# mo Markdown Preview Keymap

Date: 2026-05-20
Status: Approved

## 背景

`mo` はローカル Markdown ファイルを HTML レンダリングしてブラウザに配信する CLI ツール
（Homebrew でインストール済み: `/opt/homebrew/bin/mo`）。
バックグラウンドサーバとして動作し、デフォルトポート 6275 で起動。
`mo file.md` は既存セッションがあればファイルを追加し、なければ新規セッションを開始する。
ブラウザは自動では開かないため、別途 URL を開く必要がある。

このプロジェクトでは Markdown 編集中に「現在のバッファをブラウザでプレビューする」ショートカットを Neovim に追加したい。

## ゴール

- Markdown buffer から 1 キー操作で `mo` プレビューを開ける
- ブラウザを自動で開く（既に開いていれば live-reload で更新される）
- 既存のキーマップ・プラグイン構成と整合する

## 非ゴール（YAGNI）

- `mo --shutdown` / `--restart` / `--status` のキーバインド
- target グループ（`-t`）の指定
- ポート切り替え（6275 ハードコード）
- Markdown 以外の filetype 対応
- **既存ブラウザタブの再利用** — Chrome を含む主要ブラウザは macOS の `open URL` で
  「同じ URL でも常に新タブ」を開く。AppleScript で Chrome を直接制御すればタブ再利用は
  可能だが、Automation 権限の付与や Chrome 固有の実装などコストが高いため、本イテレーションで
  は採用しない（試作と revert を `git log` に記録済み）。連打すると新タブが増える点はユーザー
  が許容済み。

## アーキテクチャ

新規ファイル `lua/plugins/markdown.lua` を作成し、AstroCore の `opts.autocmds` を拡張する形で
`FileType markdown` 時に buffer-local キーマップを登録する。

```
lua/plugins/markdown.lua
└── { "AstroNvim/astrocore", opts = function(_, opts) ... end }
    └── opts.autocmds.markdown_preview
        └── FileType=markdown autocmd
            └── buffer-local keymap <Leader>mp
                ├─ vim.fn.expand("%:p") でフルパス取得
                ├─ 空パスなら vim.notify(WARN) で中断
                ├─ vim.system({ "mo", "--no-open", "--json", path }) でファイル登録（非同期）
                └─ 成功コールバック内:
                    ├─ vim.json.decode(stdout) で JSON パース
                    ├─ data.files から path == 自分のパスのエントリを検索
                    └─ そのエントリの url を vim.ui.open で開く
```

### URL 設計（mo の `--json` から URL を取得）

`mo` は `--json` フラグで全登録ファイルとそれぞれの URL を構造化データで返す。
出力例:

```json
{
  "url": "http://localhost:6275",
  "files": [
    { "url": "http://localhost:6275/?file=7c36eda8", "path": "/tmp/a.md", "name": "a.md" },
    { "url": "http://localhost:6275/?file=38be63a0", "path": "/tmp/b.md", "name": "b.md" }
  ]
}
```

各ファイルは独自の `?file=<id>` クエリパラメータ付き URL を持っており、`mo` 内部で生成・管理される
（私たちが target 名やハッシュを自前で組み立てる必要はない）。これによって以下を達成する:

- **正しいファイル表示**: 各ファイルの URL は `mo` が一意に発行するため、別ファイルが default group
  の最後表示に引っ張られて表示されない
- **`mo` 内蔵ブラウザ起動の抑制**: `--no-open` で `mo` 側の自動ブラウザ起動を止め、`vim.ui.open`
  に一元化する
- **race condition 回避**: `vim.ui.open` を `vim.system` の **成功コールバック内** で呼ぶ。
  `mo` がファイル登録を完了してからブラウザに URL を渡す
- **ファイルパス照合**: `data.files[i].path` と渡したパスの完全一致で対象 URL を選ぶ。
  `mo` は引数で渡したパス文字列をそのまま保存するため、シンボリックリンク解決などは不要

なお、**同じ URL を `vim.ui.open` に渡しても Chrome は新タブを開く**（macOS `open URL` の挙動）。
タブ再利用は非ゴールとしたため、連打時のタブ増加は許容している。

## コンポーネント

### `lua/plugins/markdown.lua`

- LazySpec を返す
- `"AstroNvim/astrocore"` を再オープンする形で opts を拡張
- `require("astrocore").extend_tbl(opts.autocmds or {}, { ... })` で他の autocmd 設定を壊さない
- `FileType` イベント、`pattern = "markdown"`
- callback で `vim.keymap.set("n", "<Leader>mp", fn, { buffer = args.buf, desc = "..." })`

### キーマップ

- 名前: `<Leader>mp`（markdown preview）
- スコープ: buffer-local（markdown filetype のみ）
- desc: `"Preview with mo"`（which-key に表示される）

### プレビュー関数

```lua
local function preview_with_mo()
  local path = vim.fn.expand("%:p")
  if path == "" then
    vim.notify("No file to preview", vim.log.levels.WARN)
    return
  end
  vim.system({ "mo", "--no-open", "--json", path }, { text = true }, function(result)
    if result.code ~= 0 then
      vim.schedule(function()
        vim.notify("mo failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
      end)
      return
    end
    local ok, data = pcall(vim.json.decode, result.stdout)
    if not ok or type(data) ~= "table" or type(data.files) ~= "table" then
      vim.schedule(function()
        vim.notify("mo returned unexpected JSON", vim.log.levels.ERROR)
      end)
      return
    end
    local url
    for _, f in ipairs(data.files) do
      if f.path == path then
        url = f.url
        break
      end
    end
    if not url then
      vim.schedule(function()
        vim.notify("mo did not register the file", vim.log.levels.ERROR)
      end)
      return
    end
    vim.schedule(function()
      vim.ui.open(url)
    end)
  end)
end
```

非同期コールバックを使う理由: `mo` が即時 return するとはいえ Neovim の UI スレッドをブロックしないため。
さらに `vim.ui.open` をコールバック内に置くことで、`mo` のファイル登録完了後にブラウザを開ける。

## データフロー

1. ユーザが Markdown buffer で `<Leader>mp` を押す
2. `vim.fn.expand("%:p")` で絶対パスを取得
3. パスが空（無名 buffer）なら警告して終了
4. `vim.system` で `mo --no-open --json <path>` をバックグラウンド実行
5. **成功コールバック内で**:
   - `vim.json.decode(result.stdout)` で JSON パース
   - `data.files` をループし `f.path == path` のエントリを探して `f.url` を取得
   - `vim.ui.open(url)` でブラウザを開く（毎回新タブが開く点は許容）
6. エラー時のみ `vim.notify(ERROR)` で通知（mo 実行失敗 / JSON 不正 / ファイル未登録）

## エラーハンドリング

| 状況                       | ハンドリング                                                                              |
| -------------------------- | ----------------------------------------------------------------------------------------- |
| 無名 buffer（未保存）      | `vim.notify("No file to preview", WARN)` で中断                                           |
| `mo` 非インストール / 実行失敗 | `result.code ~= 0` で ERROR 通知（`stderr` の内容を含める）                            |
| JSON パース失敗            | `pcall(vim.json.decode, ...)` で防御、不正な形式なら ERROR 通知                           |
| 渡したパスが files にない | （通常起こらないが） ERROR 通知。`mo` が path を正規化してしまった場合の保険              |
| `vim.ui.open` 失敗         | macOS デフォルトでは通常成功するため明示的なチェックは省略                                |

## テスト

手動確認のみ（Neovim 設定の単体テストは現状このリポジトリに存在しない）。

- [ ] Markdown buffer で `<Leader>mp` を押すとブラウザが `http://localhost:6275/?file=<id>` を開く
- [ ] サーバが起動していなくても初回押下でサーバが起動しブラウザが表示される
- [ ] 別の md ファイルが既に開かれていても、`<Leader>mp` を押したファイルが表示される
- [ ] 無名 buffer で押すと警告が出て何も起こらない
- [ ] Lua filetype など他のバッファでは `<Leader>mp` が未定義のまま（衝突しない）
- [ ] which-key に `mp Preview with mo` が表示される

連打すると新タブが増える点は非ゴール扱い（上記「非ゴール」参照）。

## 検討した代替案

### A. グローバル keymap（filetype 制限なし）

`mo` は stdin も受け付けるので任意 filetype のバッファを `mo` にパイプする案。
→ 「今見ているファイルを `mo` で開く」というゴールに対し、Markdown 以外は意図が曖昧。除外。

### B. `polish.lua` に置く

`init.lua` の `require "polish"` は現状無効化されており、polish 自体が活用されていない。
新規プラグインスペック追加で統一する流儀のほうがプロジェクトに馴染む。除外。

### C. `vim.system` を同期 `:wait()` する

UI スレッドが一瞬ブロックされる。非同期コールバック方式のほうが安全。

### D. URL を自前で組み立てる（`--target` + SHA-256 ハッシュ）

ファイルパスのハッシュを `--target` に渡して `http://localhost:6275/<hash>` を組み立てる案を一度検討した。
これは機能するが、`mo --json` が既にファイルごとの URL を返してくれるため、車輪の再発明だった。
URL の生成責任を `mo` 側に任せることで、`mo` 内部の URL スキーム変更にも追従しやすい。除外。

### E. AppleScript で Chrome タブを再利用

Chrome の全ウィンドウ・タブを走査して `localhost:6275` で始まるタブを navigate し直す案を実装したが、
Automation 権限の付与や Chrome 固有のロジック、AppleEvent タイムアウトのフォールバック処理など
複雑さに対して得られる UX 改善が見合わなかった。`git log` に試作 commit と revert commit を残し、
将来必要になったら参照できるようにしてある。除外。

## 実装ファイル

- 新規: `lua/plugins/markdown.lua`
- 編集: なし
