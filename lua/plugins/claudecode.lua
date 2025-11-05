return {
	"coder/claudecode.nvim",
	dependencies = {
		{ "folke/snacks.nvim", opts = { input = { enabled = true } } },
	},
	config = true,
	specs = {
		{
			"AstroNvim/astrocore",
			---@param opts AstroCoreOpts
			opts = function(_, opts)
				local maps = assert(opts.mappings)
				local prefix = "<Leader>a"

				-- Normal mode mappings
				maps.n[prefix] = { desc = require("astroui").get_icon("ClaudeCode", 1, true) .. "Claude Code" }
				maps.n[prefix .. "c"] = {
					"<cmd>ClaudeCode<cr>",
					desc = "Toggle Claude",
				}
				maps.n[prefix .. "f"] = {
					"<cmd>ClaudeCodeFocus<cr>",
					desc = "Focus Claude",
				}
				maps.n[prefix .. "r"] = {
					"<cmd>ClaudeCode --resume<cr>",
					desc = "Resume session",
				}
				maps.n[prefix .. "C"] = {
					"<cmd>ClaudeCode --continue<cr>",
					desc = "Continue session",
				}
				maps.n[prefix .. "m"] = {
					"<cmd>ClaudeCodeSelectModel<cr>",
					desc = "Select model",
				}
				maps.n[prefix .. "b"] = {
					"<cmd>ClaudeCodeAdd %<cr>",
					desc = "Add buffer",
				}
				maps.n[prefix .. "a"] = {
					"<cmd>ClaudeCodeDiffAccept<cr>",
					desc = "Accept diff",
				}
				maps.n[prefix .. "d"] = {
					"<cmd>ClaudeCodeDiffDeny<cr>",
					desc = "Deny diff",
				}

				-- Visual mode mappings
				maps.v[prefix] = { desc = require("astroui").get_icon("ClaudeCode", 1, true) .. "Claude Code" }
				maps.v[prefix .. "s"] = {
					"<cmd>ClaudeCodeSend<cr>",
					desc = "Send selection",
				}
			end,
		},
		{ "AstroNvim/astroui", opts = { icons = { ClaudeCode = "" } } },
	},
}
