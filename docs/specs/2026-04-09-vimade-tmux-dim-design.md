# Vimade + tmux Focus Dimming

## Problem

tmux の `window-style` / `window-active-style` による非アクティブペインの dim 効果が、Neovim 内では機能しない。Neovim の colorscheme (catppuccin) が `Normal` highlight group に明示的な背景色を設定するため、tmux のデフォルト背景色の変更が上書きされる。

## Solution

vimade プラグインを導入し、Neovim 側で dim 効果を実現する。tmux の `focus-events` を有効化して、ペイン間のフォーカス切り替えを Neovim に通知する。

## Scope

2つのリポジトリに変更を加える:

| Repository | File | Change |
|-----------|------|--------|
| `astronvim_config` | `lua/plugins/vimade.lua` (new) | vimade プラグインスペック追加 |
| `dotfiles` | `package/tmux/tmux.conf` | `focus-events on` 追加 |

## Design

### 1. `lua/plugins/vimade.lua` (new file)

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

Configuration rationale:

- `fadelevel = 0.4`: Default dim intensity (0.0 = fully faded, 1.0 = no fade). 40% provides noticeable but not harsh dimming.
- `enablefocusfading = true`: Enables FocusLost/FocusGained handling, which is required for tmux pane dimming.
- `ncmode = "buffers"`: Neovim splits showing the same buffer stay undimmed. Different buffers in splits are dimmed.
- `groupdiff = true`: Windows in diff mode are treated as a group (not dimmed relative to each other).
- `groupscrollbind = false`: Default; scrollbound windows are dimmed individually.
- `event = "UIEnter"`: Lazy-load after UI initialization to minimize startup impact.

### 2. `package/tmux/tmux.conf` modification

Add after line 6 (`set -g escape-time 0`):

```
set -g focus-events on
```

This enables tmux to send FocusIn/FocusOut escape sequences to Neovim. The existing `escape-time 0` setting ensures these events are delivered without delay.

### 3. Existing tmux dim settings (no change)

The existing tmux.conf already has:

```
set -g window-style bg=colour236
set -g window-active-style bg=terminal
```

These continue to handle shell pane dimming. vimade handles Neovim pane dimming independently via highlight manipulation.

## Dependencies

- Neovim 0.10+ (already in use with AstroNvim v6)
- tmux `focus-events on` (to be added)
- No Python dependency (vimade uses pure Lua on Neovim 0.8+)

## Out of Scope

- Changing the colorscheme or its background settings
- Modifying tmux `window-style` / `window-active-style`
- Custom blocklist rules for vimade
