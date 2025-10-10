-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
	"AstroNvim/astrocommunity",
	{ import = "astrocommunity.colorscheme.kanagawa-nvim" },
	{ import = "astrocommunity.completion.avante-nvim" },
	{ import = "astrocommunity.completion.copilot-lua" },
	{ import = "astrocommunity.colorscheme.catppuccin" },
	{ import = "astrocommunity.git.octo-nvim" },
	{ import = "astrocommunity.motion.leap-nvim" },
	-- { import = "astrocommunity.pack.biome" },
	{ import = "astrocommunity.pack.eslint" },
	{ import = "astrocommunity.pack.lua" },
	{ import = "astrocommunity.pack.bash" },
	{ import = "astrocommunity.pack.go" },
	{ import = "astrocommunity.pack.golangci-lint" },
	{ import = "astrocommunity.pack.markdown" },
	{ import = "astrocommunity.pack.mdx" },
	{ import = "astrocommunity.pack.prettier" },
	{ import = "astrocommunity.pack.proto" },
	{ import = "astrocommunity.pack.toml" },
	{ import = "astrocommunity.pack.yaml" },
	{ import = "astrocommunity.pack.tailwindcss" },
	{ import = "astrocommunity.pack.typescript-all-in-one" },
	{ import = "astrocommunity.pack.rust" },
	{ import = "astrocommunity.pack.python" },
	{ import = "astrocommunity.markdown-and-latex.markdown-preview-nvim" },
	{ import = "astrocommunity.recipes.vscode" },
	{ import = "astrocommunity.recipes.picker-lsp-mappings" },
}
