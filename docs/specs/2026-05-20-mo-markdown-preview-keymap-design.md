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
`FileType markdown` 時に buffer-local キーマップを登録する。ブラウザ起動部分は AppleScript を
使い既存タブの再利用を試み、失敗時は `vim.ui.open` にフォールバックする。

```
lua/plugins/markdown.lua
└── { "AstroNvim/astrocore", opts = function(_, opts) ... end }
    ├── chrome_script (AppleScript 文字列): 既存 Chrome タブ再利用ロジック
    ├── open_url(url): osascript 呼び出し + フォールバック
    └── opts.autocmds.markdown_preview
        └── FileType=markdown autocmd
            └── buffer-local keymap <Leader>mp
                ├─ vim.fn.expand("%:p") でフルパス取得
                ├─ 空パスなら vim.notify(WARN) で中断
                ├─ vim.system({ "mo", "--no-open", "--json", path }) でファイル登録（非同期）
                └─ 成功コールバック内:
                    ├─ vim.json.decode(stdout) で JSON パース
                    ├─ data.files から path == 自分のパスのエントリを検索
                    └─ open_url(entry.url) でブラウザ起動（AppleScript 経由 or fallback）
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

各ファイルは独自の `?file=<id>` クエリパラメータ付き URL を持っており、`mo` 内部で生成・管理される。
これによって以下を達成する:

- **正しいファイル表示**: 各ファイルの URL は `mo` が一意に発行するため、別ファイルが default group
  の最後表示に引っ張られて表示されない
- **`mo` 内蔵ブラウザ起動の抑制**: `--no-open` で `mo` 側の自動ブラウザ起動を止め、ブラウザ起動は
  プラグインで一元的に制御する
- **ファイルパス照合**: `data.files[i].path` と渡したパスの完全一致で対象 URL を選ぶ。
  `mo` は引数で渡したパス文字列をそのまま保存するため、シンボリックリンク解決などは不要

### ブラウザ起動戦略（既存タブの再利用）

macOS の `open URL`（および `vim.ui.open` の実体）は同じ URL であっても Chrome 等の主要ブラウザでは
**毎回新規タブを開く**。これでは `<Leader>mp` を連打する度にタブが増えてしまう。

そこで **AppleScript で Chrome のタブを直接制御** し、既存の `http://localhost:6275/*` タブを
検出してそのタブを新 URL に navigate する。具体的なフロー:

1. `osascript -e <script> <url>` を `vim.system` で呼ぶ（タイムアウト 3 秒）
2. AppleScript 内 (`with timeout of 2 seconds`):
   - System Events で Chrome プロセス存在チェック → 無ければ `"no-chrome"` を返す
   - 全 Chrome ウィンドウの全タブを列挙、URL が `http://localhost:6275` で始まる最初のタブを探す
   - 見つかったら: URL を新 URL に書き換え、そのタブを active にし、ウィンドウを foreground に
     して Chrome を `activate` → `"reused"` を返す
   - 見つからなかったら: `open location <url>` で Chrome に新タブを開かせて `activate` →
     `"opened"` を返す
3. AppleScript が `code == 0` かつ `stdout != "no-chrome"` なら成功とみなす
4. 上記以外（Automation 権限なし / タイムアウト / Chrome 不在）は **`vim.ui.open(url)` にフォールバック**

### 権限要件と graceful degradation

AppleScript で Chrome を制御するには macOS の Automation 権限が必要（System Settings →
Privacy & Security → Automation → Terminal 等 → Google Chrome をオン）。初回の osascript 呼び出しで
権限プロンプトが出る。

- **権限あり + Chrome 起動中**: 既存タブ再利用 → 完全に要求を満たす
- **権限なし / 拒否**: AppleScript がタイムアウト/エラー → `vim.ui.open` にフォールバック
  （新タブが開く。以前の挙動と同等）
- **Chrome 未起動**: `"no-chrome"` 検出 → `vim.ui.open` で OS デフォルトブラウザで開く

ユーザーが Chrome 以外のブラウザをデフォルトに設定している場合も、フォールバックの `vim.ui.open` が
OS デフォルトを使うので機能する（タブ再利用は得られないが previewは開く）。

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

### AppleScript と open_url 関数

```lua
local chrome_script = [[
on run argv
	set targetURL to item 1 of argv
	with timeout of 2 seconds
		tell application "System Events"
			if not (exists process "Google Chrome") then return "no-chrome"
		end tell
		tell application "Google Chrome"
			repeat with w in windows
				set tabList to tabs of w
				repeat with i from 1 to count of tabList
					if (URL of (item i of tabList)) starts with "http://localhost:6275" then
						set URL of (item i of tabList) to targetURL
						set active tab index of w to i
						set index of w to 1
						activate
						return "reused"
					end if
				end repeat
			end repeat
			open location targetURL
			activate
			return "opened"
		end tell
	end timeout
end run
]]

local function open_url(url)
  vim.system(
    { "osascript", "-e", chrome_script, url },
    { text = true, timeout = 3000 },
    function(result)
      local out = result.stdout or ""
      if result.code == 0 and not out:find("no-chrome") then
        return  -- Chrome reused or opened a tab successfully
      end
      vim.schedule(function()
        vim.ui.open(url)  -- fallback: default browser, new tab
      end)
    end
  )
end
```

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
    open_url(url)
  end)
end
```

非同期コールバックを使う理由: `mo` が即時 return するとはいえ Neovim の UI スレッドをブロックしないため。
さらに `open_url` をコールバック内に置くことで、`mo` のファイル登録完了後にブラウザを開ける。

## データフロー

1. ユーザが Markdown buffer で `<Leader>mp` を押す
2. `vim.fn.expand("%:p")` で絶対パスを取得
3. パスが空（無名 buffer）なら警告して終了
4. `vim.system` で `mo --no-open --json <path>` をバックグラウンド実行
5. **mo の成功コールバック内で**:
   - `vim.json.decode(result.stdout)` で JSON パース
   - `data.files` をループし `f.path == path` のエントリを探して `f.url` を取得
   - `open_url(url)` を呼ぶ
6. **`open_url` 内部**:
   - `osascript -e <chrome_script> <url>` を `vim.system` で非同期実行（timeout 3 秒）
   - 成功（`code == 0` かつ stdout が `no-chrome` を含まない）→ 完了
   - 失敗 → `vim.schedule(function() vim.ui.open(url) end)` でフォールバック
7. エラー時のみ `vim.notify(ERROR)` で通知（mo 実行失敗 / JSON 不正 / ファイル未登録）

## エラーハンドリング

| 状況                              | ハンドリング                                                                            |
| --------------------------------- | --------------------------------------------------------------------------------------- |
| 無名 buffer（未保存）             | `vim.notify("No file to preview", WARN)` で中断                                         |
| `mo` 非インストール / 実行失敗    | `result.code ~= 0` で ERROR 通知（`stderr` の内容を含める）                             |
| JSON パース失敗                   | `pcall(vim.json.decode, ...)` で防御、不正な形式なら ERROR 通知                         |
| 渡したパスが files にない         | （通常起こらないが） ERROR 通知。`mo` が path を正規化してしまった場合の保険            |
| Chrome 未起動 / Automation 権限なし / AppleScript タイムアウト | `open_url` が自動で `vim.ui.open` にフォールバック         |
| `vim.ui.open` 失敗                | macOS デフォルトでは通常成功するため明示的なチェックは省略                              |

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

### D. URL を自前で組み立てる（`--target` + SHA-256 ハッシュ）

ファイルパスのハッシュを `--target` に渡して `http://localhost:6275/<hash>` を組み立てる案を一度検討した。
これは機能するが、`mo --json` が既にファイルごとの URL を返してくれるため、車輪の再発明だった。
URL の生成責任を `mo` 側に任せることで、`mo` 内部の URL スキーム変更にも追従しやすい。除外。

## 実装ファイル

- 新規: `lua/plugins/markdown.lua`
- 編集: なし
