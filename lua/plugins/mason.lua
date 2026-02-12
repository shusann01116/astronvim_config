---@type LazySpec
return {
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		opts = {
			ensure_installed = {
				"lua-language-server",
				"stylua",
				"oxlint",
				"oxfmt",
				"prettierd",
			},
		},
	},
}
