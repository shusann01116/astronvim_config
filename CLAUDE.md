# AstroNvim v5 User Config

## Architecture

`init.lua` bootstraps lazy.nvim, then calls `lazy_setup.lua` which loads `community.lua` → `plugins/*.lua` via `lazy.setup()`. After that, `init.lua` runs `require "polish"` (currently disabled; pure Lua, not a lazy.nvim spec).

`community.lua` is imported BEFORE `plugins/` in `lazy_setup.lua`. Community packs set base config; files in `plugins/` override them. To add a language pack, add to `community.lua`. To customize a plugin, add/edit a file in `plugins/`.

## Conventions

- Indent: **tabs** (some template-origin files still use spaces; use tabs for new/edited code)
- Annotate top-level return: `---@type LazySpec`
- Single plugin: `return { "author/plugin.nvim", opts = { ... } }`
- Multiple specs from one file: `return { { ... }, { ... } }`
- Keymaps via AstroCore opts function pattern:
  ```lua
  opts = function(_, opts)
    local maps = assert(opts.mappings)
    maps.n["<key>"] = { "<cmd>...<cr>", desc = "..." }
  end
  ```
- Extending opts safely: `require("astrocore").extend_tbl(opts.field or {}, { ... })`

## Gotchas

- **lazy-lock.json**: Must be committed — it pins all plugin versions.
- **Formatter logic** (none-ls.lua): JS/TS uses oxfmt when `.oxfmtrc.json(c)` exists in project, prettierd otherwise. Other filetypes always use prettierd. Both use `runtime_condition` to switch at runtime.
- **oxlint**: Registered as LSP server in `astrolsp.lua`, NOT as a none-ls source. `none-ls.lua` has a no-op handler to suppress auto-registration.
- **LSP formatting disabled** for: vtsls, oxlint (in `astrolsp.lua`).
- **Mason** (`mason.lua`): Uses `mason-tool-installer.nvim`, not `mason-lspconfig`. Add tools to `ensure_installed` there.

## Linting

Lua is linted with selene (neovim std). All explicitly listed rules in `selene.toml` are set to `allow`; unlisted rules use selene defaults.
