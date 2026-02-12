---@type LazySpec
return {
	"AstroNvim/astrolsp",
	---@param opts AstroLSPOpts
	opts = function(_, opts)
		opts.servers = opts.servers or {}
		table.insert(opts.servers, "oxlint")
		opts.formatting = require("astrocore").extend_tbl(opts.formatting or {}, {
			disabled = { "vtsls", "oxlint" },
		})
		opts.config = require("astrocore").extend_tbl(opts.config or {}, {
			tailwindcss = {
				settings = {
					classFunctions = { "cva", "cx" },
				},
			},
			oxlint = {
				root_dir = require("lspconfig.util").root_pattern("package.json", ".oxlintrc.json"),
			},
		})
	end,
}
