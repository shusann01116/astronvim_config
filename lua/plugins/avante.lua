---@type LazySpec
return {
	{
		"yetone/avante.nvim",
		opts = function(_, opts)
			return require("astrocore").extend_tbl(opts, {
				mappings = {
					submit = {
						insert = "<C-a>",
					},
				},
			})
		end,
	},
}
