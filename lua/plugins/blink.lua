---@type LazySpec
return {
	{ "xzbdmw/colorful-menu.nvim",   lazy = true },
	{ "nvim-tree/nvim-web-devicons", lazy = true },
	{ "onsails/lspkind.nvim",        lazy = true },
	{
		"saghen/blink.cmp",
		dependencies = { "xzbdmw/colorful-menu.nvim", "nvim-tree/nvim-web-devicons", "onsails/lspkind.nvim" },
		opts = {
			keymap = {
				["<C-e>"] = { "cancel", "fallback" },
			},
			completion = {
				menu = {
					draw = {
						columns = { { "kind_icon" }, { "label", gap = 1 } },
						components = {
							kind_icon = {
								text = function(ctx)
									local icon = ctx.kind_icon
									if vim.tbl_contains({ "Path" }, ctx.source_name) then
										local dev_icon, _ = require("nvim-web-devicons").get_icon(ctx.label)
										if dev_icon then
											icon = dev_icon
										end
									else
										icon = require("lspkind").symbolic(ctx.kind, {
											mode = "symbol",
										})
									end

									return icon .. ctx.icon_gap
								end,
								highlight = function(ctx)
									local hl = ctx.kind_hl
									if vim.tbl_contains({ "Path" }, ctx.source_name) then
										local dev_icon, dev_hl = require("nvim-web-devicons").get_icon(ctx.label)
										if dev_icon then
											hl = dev_hl
										end
									end
									return hl
								end,
							},
							label = {
								text = function(ctx)
									return require("colorful-menu").blink_components_text(ctx)
								end,
								highlight = function(ctx)
									return require("colorful-menu").blink_components_highlight(ctx)
								end,
							},
						},
					},
				},
			},
		},
	},
}
