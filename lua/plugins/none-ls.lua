---@type LazySpec
return {
	"jay-babu/mason-null-ls.nvim",
	opts = function(_, opts)
		local null_ls = require("null-ls")
		local h = require("null-ls.helpers")
		local cmd_resolver = require("null-ls.helpers.command_resolver")

		local js_ts_fts = {
			javascript = true,
			javascriptreact = true,
			typescript = true,
			typescriptreact = true,
		}

		local has_oxfmt_config = function(params)
			return vim.fs.find(
				{ ".oxfmtrc.json", ".oxfmtrc.jsonc" },
				{ path = vim.fn.fnamemodify(params.bufname, ":h"), upward = true }
			)[1] ~= nil
		end

		if not opts.handlers then opts.handlers = {} end

		-- prettierd: JS/TS では oxfmt 設定がない場合のみ、それ以外は常に実行
		opts.handlers.prettierd = function()
			null_ls.register(
				null_ls.builtins.formatting.prettierd.with({
					runtime_condition = function(params)
						if js_ts_fts[params.ft] then
							return not has_oxfmt_config(params)
						end
						return true
					end,
				})
			)
		end

		-- oxfmt: JS/TS で設定ファイルがある場合のみ (lspconfig 未対応のため none-ls で登録)
		opts.handlers.oxfmt = function()
			null_ls.register({
				name = "oxfmt",
				method = null_ls.methods.FORMATTING,
				filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
				generator = h.formatter_factory({
					command = "oxfmt",
					args = { "--stdin-filepath", "$FILENAME" },
					to_stdin = true,
					dynamic_command = cmd_resolver.from_node_modules(),
					runtime_condition = has_oxfmt_config,
				}),
			})
		end

		-- oxlint: LSP サーバーとして astrolsp.lua で設定済み。自動登録を抑制
		opts.handlers.oxlint = function() end
	end,
}
