# mo Markdown Preview Keymap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Markdown buffer で `<Leader>mp` を押すと `mo` でプレビューが起動し、ブラウザが自動的に開く buffer-local キーマップを追加する。

**Architecture:** 新規 `lua/plugins/markdown.lua` で AstroCore の opts を再オープンし、`opts.autocmds` を `astrocore.extend_tbl` 経由で拡張する。`FileType=markdown` autocmd でバッファローカルに `<Leader>mp` を登録し、callback で `vim.system({"mo", path})` 非同期実行と `vim.ui.open("http://localhost:6275/")` を呼ぶ。

**Tech Stack:** Neovim (Lua), AstroNvim v5, AstroCore, `mo` CLI (Homebrew installed at `/opt/homebrew/bin/mo`)

**Spec:** `docs/specs/2026-05-20-mo-markdown-preview-keymap-design.md`

**Testing model:** このリポジトリには自動テストが存在しないため、各タスクは「Neovim を再起動して手動確認」をテストステップとする。spec の手動確認チェックリストを完全実行することが完了条件。

---

## File Structure

- **Create**: `lua/plugins/markdown.lua` — 唯一の新規ファイル。AstroCore opts を関数で受け取り autocmd を追加する LazySpec を返す。
- **Modify**: なし

---

### Task 1: Markdown プレビュー keymap を実装する

**Files:**
- Create: `lua/plugins/markdown.lua`

このタスクは 1 ファイルで完結する。手動確認は Task 2 でまとめて行う。

- [ ] **Step 1: 新規ファイル `lua/plugins/markdown.lua` を作成する**

以下の内容で書き出す（インデントはタブ。プロジェクト規約）。

```lua
---@type LazySpec
return {
	"AstroNvim/astrocore",
	---@param opts AstroCoreOpts
	opts = function(_, opts)
		local astrocore = require("astrocore")
		opts.autocmds = astrocore.extend_tbl(opts.autocmds or {}, {
			markdown_preview = {
				{
					event = "FileType",
					pattern = "markdown",
					desc = "Bind <Leader>mp to preview markdown with mo",
					callback = function(args)
						vim.keymap.set("n", "<Leader>mp", function()
							local path = vim.fn.expand("%:p")
							if path == "" then
								vim.notify("No file to preview", vim.log.levels.WARN)
								return
							end
							vim.system({ "mo", path }, { text = true }, function(result)
								if result.code ~= 0 then
									vim.schedule(function()
										vim.notify(
											"mo failed: " .. (result.stderr or ""),
											vim.log.levels.ERROR
										)
									end)
								end
							end)
							vim.ui.open("http://localhost:6275/")
						end, { buffer = args.buf, desc = "Preview with mo" })
					end,
				},
			},
		})
	end,
}
```

**実装上の注意:**
- インデントは **タブ** 必須（CLAUDE.md の規約）
- `---@type LazySpec` を最上位 return に付ける
- `astrocore.extend_tbl` で既存 autocmds を破壊しない
- `vim.system` の第3引数はコールバック（非同期）。UI スレッドをブロックしない
- `vim.schedule` でラップするのは、コールバックが fast event context で動くため `vim.notify` が直接呼べないから
- `vim.ui.open` は Neovim 0.10+ で利用可能（AstroNvim v5 が要求するバージョン）

- [ ] **Step 2: ファイル内容を確認する**

Run: `cat lua/plugins/markdown.lua`

Expected: 上記のコードが完全に書き出されている。タブインデントになっている（スペースではない）。

確認コマンド（タブが含まれるか）:

Run: `grep -P "^\t" lua/plugins/markdown.lua | head -3`

Expected: タブで始まる行が見つかる（GNU grep がない macOS なら `grep -E "$(printf '^\t')"` を使う）。

- [ ] **Step 3: Lua 構文を確認する**

Run: `nvim --headless -c "luafile lua/plugins/markdown.lua" -c "qa" 2>&1`

Expected: エラー出力なし（空出力）。LazySpec を返す関数なので、`luafile` でロードしてもエラーにならないこと。

もしエラーが出たら、構文エラー箇所を確認して修正後にこのステップを再実行する。

- [ ] **Step 4: 中間 commit（コードのみ、手動確認前）**

```bash
git add lua/plugins/markdown.lua
git commit -m "Add mo markdown preview keymap"
```

このコミットは「コードが書かれて構文エラーがない」状態を記録するもの。手動確認で問題が見つかれば Task 2 で fixup commit する。

---

### Task 2: 手動確認チェックリストを実行する

**Files:**
- Test: なし（手動操作）

このタスクは Neovim を実際に起動して動作確認する。各項目で問題があれば Task 1 のコードを修正し、修正コミットを積む。

- [ ] **Step 1: 事前確認 — `mo` がインストールされているか**

Run: `which mo`

Expected: `/opt/homebrew/bin/mo`（または PATH 内のいずれか）。見つからない場合は `brew install mo` 相当が必要だが、本プロジェクトは既にインストール済みの前提。

- [ ] **Step 2: 事前確認 — 既存の mo サーバを停止する（クリーンな状態でテスト）**

Run: `mo --shutdown 2>/dev/null; sleep 1`

Expected: エラーが出ても無視（動いていなければエラーになる）。テストを既知の状態から始めるための準備。

- [ ] **Step 3: Neovim を新規起動し、サンプル Markdown を開く**

```bash
echo "# Hello mo" > /tmp/mo-test.md
nvim /tmp/mo-test.md
```

- [ ] **Step 4: 手動確認 #1 — `<Leader>mp` でブラウザが開くか**

Neovim 上で normal mode のまま `<Leader>mp` を押す。

Expected:
- ブラウザで `http://localhost:6275/` が開く
- 表示内容に "Hello mo" が含まれる（多少時間がかかる場合がある）
- Neovim 側にエラー通知が出ない

問題がある場合の調査:
- `:messages` でエラーログ確認
- `mo --status` でサーバが動いているか確認
- `vim.ui.open` が利用可能か `:lua print(vim.ui.open)` で確認

- [ ] **Step 5: 手動確認 #2 — which-key に表示されるか**

Neovim で `<Leader>m` まで押して which-key の表示を待つ（通常 1 秒）。

Expected: `p Preview with mo` が一覧に表示される。

- [ ] **Step 6: 手動確認 #3 — 無名 buffer での挙動**

Neovim で `:enew` → `:set filetype=markdown` を実行後、`<Leader>mp` を押す。

Expected: `"No file to preview"` の警告が `:messages` で確認できる。ブラウザは開かない。

- [ ] **Step 7: 手動確認 #4 — 非 Markdown buffer での衝突がないこと**

Neovim で `nvim lua/plugins/markdown.lua` を新規起動し、Lua filetype のバッファで `<Leader>mp` を押す。

Expected: 何も起きない（キーマップが未定義）。または `<Leader>m` プレフィックスが未使用なら which-key が "no mapping" 的な表示を出す。

- [ ] **Step 8: 手動確認 #5 — live-reload の確認**

Step 4 のブラウザを開いたまま、Neovim で `/tmp/mo-test.md` を編集し `# Hello mo updated` に変更後 `:w` で保存。

Expected: ブラウザの表示が自動更新されて "updated" の文字が出る（`mo` の live-reload 機能による）。

- [ ] **Step 9: クリーンアップ**

Run: `mo --shutdown && rm /tmp/mo-test.md`

Expected: サーバ停止メッセージ、ファイル削除。

- [ ] **Step 10: 手動確認の結果を spec の checklist に反映する（任意）**

`docs/specs/2026-05-20-mo-markdown-preview-keymap-design.md` の「テスト」セクションのチェックボックスを埋める。

- [ ] **Step 11: 必要に応じて fixup commit**

手動確認で問題が見つかり Task 1 を修正した場合のみ:

```bash
git add lua/plugins/markdown.lua
git commit -m "Fix mo preview keymap (manual verification feedback)"
```

問題がなければこの step はスキップ。

---

## Self-Review チェック結果

**Spec coverage:**
- ゴール「Markdown buffer から 1 キーでプレビュー」→ Task 1 Step 1 で実装、Task 2 Step 4 で確認 ✓
- ゴール「ブラウザを自動で開く」→ Task 1 Step 1 の `vim.ui.open`、Task 2 Step 4 で確認 ✓
- ゴール「既存構成と整合」→ `astrocore.extend_tbl` 使用、タブインデント遵守 ✓
- 非ゴール（shutdown/restart/status keybind, target, port, 他 filetype）→ 全部含めていない ✓
- アーキテクチャ図のすべての要素 → Task 1 Step 1 のコードに対応 ✓
- エラーハンドリング 3 ケース → Task 1 Step 1 で `vim.notify` 警告、`vim.system` callback、`vim.ui.open` の戻り値（注: `vim.ui.open` のエラー処理は spec で「macOS デフォルトでは通常成功」と緩い扱いなので明示的なチェックは省略。問題が出たら Task 2 で発見される）
- テストチェックリスト 5 項目 → Task 2 Step 4-8 に対応 ✓

**Placeholder scan:** TBD/TODO/プレースホルダーなし ✓

**Type consistency:** 単一ファイルかつ単一関数なので型・名前の不整合なし ✓
