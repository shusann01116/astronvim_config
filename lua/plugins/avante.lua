---@type LazySpec
return {
	"zbirenbaum/copilot.lua",
	{
		"yetone/avante.nvim",
		opts = function(_, opts)
			return require("astrocore").extend_tbl(opts, {
				behavior = {
					auto_suggestions = true,
				},
				mappings = {
					submit = {
						insert = "<C-a>",
					},
				},
			})
		end,
	},
}
