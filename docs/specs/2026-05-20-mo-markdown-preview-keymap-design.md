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
                ├─ target = vim.fn.sha256(path):sub(1,12) — ファイルごとに一意で安定
                ├─ vim.system({ "mo", "--target", target, "--no-open", path }) でサーバ登録（非同期）
                └─ 成功コールバック内で vim.ui.open("http://localhost:6275/<target>")
```

### URL 設計（ファイルごとの一意 URL）

`mo` の `--target` フラグは URL パスセグメントになる（例: `http://localhost:6275/abc123def456`）。
ファイルパスの SHA-256 ハッシュ先頭 12 文字を target に使うことで以下を達成する:

- **正しいファイル表示**: 各ファイルが独立した URL を持つため、別ファイルが default group の最後表示
  に引っ張られて表示されない
- **既存ウィンドウ再利用**: macOS の `open URL`（`vim.ui.open` の実体）は同じ URL の既存ブラウザ
  タブをフォアグラウンドに持ってくる挙動を持つ。同じファイルを再度プレビューすると新タブを開かず
  既存タブを再利用する
- **`mo` 内蔵ブラウザ起動の抑制**: `--no-open` で `mo` 側の自動ブラウザ起動を止め、`vim.ui.open`
  に一元化する。これによって URL とブラウザ起動タイミングを完全に制御できる
- **race condition 回避**: `vim.ui.open` を `vim.system` の **成功コールバック内** で呼ぶ。
  `mo` がファイル登録を完了してからブラウザに URL を渡す

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
  local target = vim.fn.sha256(path):sub(1, 12)
  local url = "http://localhost:6275/" .. target
  vim.system({ "mo", "--target", target, "--no-open", path }, { text = true }, function(result)
    if result.code ~= 0 then
      vim.schedule(function()
        vim.notify("mo failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
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
4. `vim.fn.sha256(path):sub(1, 12)` で安定した target 名を計算
5. `vim.system` で `mo --target <hash> --no-open <path>` をバックグラウンド実行
6. **成功コールバック内で** `vim.ui.open("http://localhost:6275/<hash>")` を呼ぶ
   - 同じファイルなら同じ URL → macOS の `open` が既存ブラウザタブを再利用
   - 別ファイルなら別 URL → 新規タブで開く（ただし default group との競合は起きない）
7. `mo` 実行失敗時のみ `vim.notify(ERROR)` で通知

## エラーハンドリング

| 状況                  | ハンドリング                                                             |
| --------------------- | ------------------------------------------------------------------------ |
| 無名 buffer（未保存） | `vim.notify("No file to preview", WARN)` で中断                          |
| `mo` 非インストール   | `vim.system` のコールバックで `result.code ~= 0` 判定し ERROR 通知       |
| `vim.ui.open` 失敗    | 戻り値の error を確認、失敗時のみ通知（macOS デフォルトでは通常成功）    |

## テスト

手動確認のみ（Neovim 設定の単体テストは現状このリポジトリに存在しない）。

- [ ] Markdown buffer で `<Leader>mp` を押すとブラウザが `http://localhost:6275/<hash>` を開く
- [ ] サーバが起動していなくても初回押下でサーバが起動しブラウザが表示される
- [ ] 別の md ファイルが既に開かれていても、`<Leader>mp` を押したファイルが表示される
- [ ] 同じファイルで `<Leader>mp` を 2 回押すと新タブが増えず既存タブが再利用される
- [ ] 無名 buffer で押すと警告が出て何も起こらない
- [ ] Lua filetype など他のバッファでは `<Leader>mp` が未定義のまま（衝突しない）
- [ ] which-key に `mp Preview with mo` が表示される

## 検討した代替案

### A. グローバル keymap（filetype 制限なし）

`mo` は stdin も受け付けるので任意 filetype のバッファを `mo` にパイプする案。
→ 「今見ているファイルを `mo` で開く」というゴールに対し、Markdown 以外は意図が曖昧。除外。

### B. `polish.lua` に置く

`init.lua` の `require "polish"` は現状無効化されており、polish 自体が活用されていない。
新規プラグインスペック追加で統一する流儀のほうがプロジェクトに馴染む。除外。

### C. `vim.system` を同期 `:wait()` する

UI スレッドが一瞬ブロックされる。非同期コールバック方式のほうが安全。

## 実装ファイル

- 新規: `lua/plugins/markdown.lua`
- 編集: なし
