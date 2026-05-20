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
							vim.system(
								{ "mo", "--no-open", "--json", path },
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
									local ok, data = pcall(vim.json.decode, result.stdout)
									if not ok or type(data) ~= "table" or type(data.files) ~= "table" then
										vim.schedule(function()
											vim.notify("mo returned unexpected JSON", vim.log.levels.ERROR)
										end)
										return
									end
									local url
									for _, f in ipairs(data.files) do
										if f.path == path then
											url = f.url
											break
										end
									end
									if not url then
										vim.schedule(function()
											vim.notify("mo did not register the file", vim.log.levels.ERROR)
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
