---@type LazySpec
return {
	"flexphere/fude.nvim",
	opts = {
		file_list_mode = "snacks",
	},
	config = function(_, opts)
		require("fude").setup(opts)

		-- preview バッファは buflisted=false のため heirline の winbar が無効化され、
		-- source 側 (winbar あり) と 1 行高さがずれる。preview_win に空 winbar を
		-- 強制してペインの上端を揃える。heirline は winbar 値が自身の式と一致した
		-- 場合のみリセットするので " " は sticky になる。
		local preview = require("fude.preview")
		local original_open = preview.open_preview
		preview.open_preview = function(source_win)
			original_open(source_win)
			vim.schedule(function()
				local pwin = require("fude.config").state.preview_win
				if pwin and vim.api.nvim_win_is_valid(pwin) then vim.wo[pwin].winbar = " " end
			end)
		end
	end,
	cmd = {
		"FudeReviewStart",
		"FudeReviewStop",
		"FudeReviewToggle",
		"FudeReviewDiff",
		"FudeReviewComment",
		"FudeReviewSuggest",
		"FudeReviewViewComment",
		"FudeReviewListComments",
		"FudeReviewFiles",
		"FudeReviewScope",
		"FudeReviewScopeNext",
		"FudeReviewScopePrev",
		"FudeReviewOverview",
		"FudeReviewSubmit",
		"FudeOpenPRURL",
		"FudeCopyPRURL",
		"FudeReviewViewed",
		"FudeReviewUnviewed",
		"FudeReviewReload",
		"FudeCreatePR",
		"FudeReviewPanel",
		"FudeReviewNextFile",
		"FudeReviewPrevFile",
	},
	specs = {
		{
			"AstroNvim/astrocore",
			---@param opts AstroCoreOpts
			opts = function(_, opts)
				local maps = assert(opts.mappings)
				local prefix = "<Leader>v"

				-- Normal mode mappings
				maps.n[prefix] = { desc = require("astroui").get_icon("Fude", 1, true) .. "Fude Review" }
				maps.n[prefix .. "t"] = { "<cmd>FudeReviewToggle<cr>", desc = "Toggle" }
				maps.n[prefix .. "s"] = { "<cmd>FudeReviewStart<cr>", desc = "Start" }
				maps.n[prefix .. "q"] = { "<cmd>FudeReviewStop<cr>", desc = "Stop" }
				maps.n[prefix .. "c"] = { "<cmd>FudeReviewComment<cr>", desc = "Comment" }
				maps.n[prefix .. "S"] = { "<cmd>FudeReviewSuggest<cr>", desc = "Suggest change" }
				maps.n[prefix .. "v"] = { "<cmd>FudeReviewViewComment<cr>", desc = "View comments" }
				maps.n[prefix .. "f"] = { "<cmd>FudeReviewFiles<cr>", desc = "Changed files" }
				maps.n[prefix .. "o"] = { "<cmd>FudeReviewOverview<cr>", desc = "PR Overview" }
				maps.n[prefix .. "d"] = { "<cmd>FudeReviewDiff<cr>", desc = "Toggle diff" }
				maps.n[prefix .. "b"] = { "<cmd>FudeOpenPRURL<cr>", desc = "Open PR in browser" }
				maps.n[prefix .. "y"] = { "<cmd>FudeCopyPRURL<cr>", desc = "Copy PR URL" }
				maps.n[prefix .. "C"] = { "<cmd>FudeReviewScope<cr>", desc = "Select scope" }
				maps.n[prefix .. "]"] = { "<cmd>FudeReviewScopeNext<cr>", desc = "Next scope" }
				maps.n[prefix .. "["] = { "<cmd>FudeReviewScopePrev<cr>", desc = "Prev scope" }
				maps.n[prefix .. "l"] = { "<cmd>FudeReviewListComments<cr>", desc = "List comments" }
				maps.n[prefix .. "r"] = {
					function() require("fude.comments").reply_to_comment() end,
					desc = "Reply",
				}
				maps.n[prefix .. "R"] = { "<cmd>FudeReviewReload<cr>", desc = "Reload data" }
				maps.n[prefix .. "m"] = { "<cmd>FudeReviewViewed<cr>", desc = "Mark viewed" }
				maps.n[prefix .. "M"] = { "<cmd>FudeReviewUnviewed<cr>", desc = "Unmark viewed" }
				maps.n[prefix .. "p"] = { "<cmd>FudeReviewSubmit<cr>", desc = "Submit review" }
				maps.n[prefix .. "P"] = { "<cmd>FudeCreatePR<cr>", desc = "Create PR" }
				maps.n[prefix .. "n"] = { "<cmd>FudeReviewPanel<cr>", desc = "Toggle side panel" }
				maps.n[prefix .. "j"] = { "<cmd>FudeReviewNextFile<cr>", desc = "Next file" }
				maps.n[prefix .. "k"] = { "<cmd>FudeReviewPrevFile<cr>", desc = "Prev file" }

				-- Visual mode mappings
				maps.v[prefix] = { desc = require("astroui").get_icon("Fude", 1, true) .. "Fude Review" }
				maps.v[prefix .. "c"] = { ":FudeReviewComment<cr>", desc = "Comment (selection)" }
				maps.v[prefix .. "S"] = { ":FudeReviewSuggest<cr>", desc = "Suggest change (selection)" }
			end,
		},
		{ "AstroNvim/astroui", opts = { icons = { Fude = "󰏬" } } },
	},
}
