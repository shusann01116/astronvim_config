---@type LazySpec
return {
	"folke/snacks.nvim",
	opts = {
		picker = {
			sources = {
				files = {
					hidden = true,
				},
				grep = {
					hidden = true,
				},
			},
			win = {
				input = {
					keys = {
						["<c-l>"] = { "preview_scroll_right", mode = { "i", "n" } },
						["<c-h>"] = { "preview_scroll_left", mode = { "i", "n" } },
					},
				},
			},
		},
	},
}
