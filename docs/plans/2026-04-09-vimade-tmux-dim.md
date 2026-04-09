# Vimade + tmux Focus Dimming Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Neovim で tmux ペインの dim 効果を機能させるために vimade プラグインを導入し、tmux の focus-events を有効化する。

**Architecture:** vimade プラグインが FocusLost/FocusGained イベントを受け取り、非アクティブペイン・ウィンドウの highlight を操作して dim 効果を実現する。tmux 側で focus-events on を設定して、ペイン切り替え時にイベントを Neovim へ送信する。

**Tech Stack:** Neovim (AstroNvim v6 / lazy.nvim), tmux, vimade (Lua)

---

## File Structure

| Action | Repository | File | Responsibility |
|--------|-----------|------|----------------|
| Create | astronvim_config | `lua/plugins/vimade.lua` | vimade プラグインの lazy.nvim スペックと設定 |
| Modify | dotfiles | `package/tmux/tmux.conf` | focus-events on の追加 |

---

### Task 1: tmux.conf に focus-events on を追加

**Files:**
- Modify: `/Users/shusann/src/github.com/shusann01116/dotfiles/package/tmux/tmux.conf:6` (after `escape-time 0`)

- [ ] **Step 1: tmux.conf に `focus-events on` を追加**

`set -g escape-time 0` の直後（7行目）に以下を挿入する:

```
set -g focus-events on
```

変更後、6-7行目は以下のようになる:

```
set -g escape-time 0
set -g focus-events on
```

- [ ] **Step 2: 手動検証 — tmux で focus-events が有効か確認**

Run: `tmux show-options -g focus-events`
Expected: `focus-events on`

注: tmux.conf を再読み込みするか、新しい tmux セッションを起動して確認する。既存セッションでは `tmux source-file ~/.tmux.conf` で再読み込み可能。

- [ ] **Step 3: コミット**

```bash
git -C /Users/shusann/src/github.com/shusann01116/dotfiles add package/tmux/tmux.conf
git -C /Users/shusann/src/github.com/shusann01116/dotfiles commit -m 'Enable focus-events for Neovim tmux pane dimming'
```

---

### Task 2: vimade プラグインを AstroNvim 設定に追加

**Files:**
- Create: `/Users/shusann/src/github.com/shusann01116/astronvim_config/lua/plugins/vimade.lua`

- [ ] **Step 1: `lua/plugins/vimade.lua` を作成**

以下の内容で新規ファイルを作成する:

```lua
---@type LazySpec
return {
	"tadaa/vimade",
	event = "UIEnter",
	opts = {
		fadelevel = 0.4,
		enablefocusfading = true,
		ncmode = "buffers",
		groupdiff = true,
		groupscrollbind = false,
	},
}
```

- [ ] **Step 2: selene lint が通ることを確認**

Run: `selene lua/plugins/vimade.lua`
Expected: エラーなし（warning も出ない）

- [ ] **Step 3: Neovim で vimade が読み込まれることを手動検証**

Neovim を起動し、以下を実行:

```vim
:Lazy check vimade
```

vimade がプラグインリストに表示され、読み込まれていることを確認する。

- [ ] **Step 4: tmux ペイン間の dim 動作を手動検証**

1. tmux で2つのペインを開き、片方で Neovim を起動
2. もう片方のペインにフォーカスを移す
3. Neovim のペインが dim（暗く）なることを確認
4. Neovim のペインに戻るとフルカラーに戻ることを確認

- [ ] **Step 5: コミット**

```bash
git -C /Users/shusann/src/github.com/shusann01116/astronvim_config add lua/plugins/vimade.lua
git -C /Users/shusann/src/github.com/shusann01116/astronvim_config commit -m 'Add vimade plugin for inactive pane and window dimming'
```

- [ ] **Step 6: lazy-lock.json をコミット**

Neovim 起動後に vimade がインストールされると `lazy-lock.json` が更新される。これもコミットする:

```bash
git -C /Users/shusann/src/github.com/shusann01116/astronvim_config add lazy-lock.json
git -C /Users/shusann/src/github.com/shusann01116/astronvim_config commit -m 'Update lazy-lock.json with vimade pin'
```
