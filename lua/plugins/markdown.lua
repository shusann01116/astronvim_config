---@type LazySpec
return {
	"AstroNvim/astrocore",
	---@param opts AstroCoreOpts
	opts = function(_, opts)
		local astrocore = require("astrocore")
		opts.autocmds = astrocore.extend_tbl(opts.autocmds or {}, {
			markdown_preview = {
				{
					event = "FileType",
					pattern = "markdown",
					desc = "Bind <Leader>mp to preview markdown with mo",
					callback = function(args)
						vim.keymap.set("n", "<Leader>mp", function()
							local path = vim.fn.expand("%:p")
							if path == "" then
								vim.notify("No file to preview", vim.log.levels.WARN)
								return
							end
							local target = vim.fn.sha256(path):sub(1, 12)
							local url = "http://localhost:6275/" .. target
							vim.system(
								{ "mo", "--target", target, "--no-open", path },
								{ text = true },
								function(result)
									if result.code ~= 0 then
										vim.schedule(function()
											vim.notify(
												"mo failed: " .. (result.stderr or ""),
												vim.log.levels.ERROR
											)
										end)
										return
									end
									vim.schedule(function()
										vim.ui.open(url)
									end)
								end
							)
						end, { buffer = args.buf, desc = "Preview with mo" })
					end,
				},
			},
		})
	end,
}
