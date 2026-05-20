---@type LazySpec
return {
	"AstroNvim/astrocore",
	---@param opts AstroCoreOpts
	opts = function(_, opts)
		local astrocore = require("astrocore")

		-- AppleScript that locates an existing Chrome tab on localhost:6275 and
		-- navigates it to the target URL. Falls back to opening a new tab inside
		-- Chrome if none was found. Returns one of: "reused" / "opened" /
		-- "no-chrome" / errors out on timeout (caller falls back to vim.ui.open).
		local chrome_script = [[
on run argv
	set targetURL to item 1 of argv
	with timeout of 2 seconds
		tell application "System Events"
			if not (exists process "Google Chrome") then return "no-chrome"
		end tell
		tell application "Google Chrome"
			repeat with w in windows
				set tabList to tabs of w
				repeat with i from 1 to count of tabList
					if (URL of (item i of tabList)) starts with "http://localhost:6275" then
						set URL of (item i of tabList) to targetURL
						set active tab index of w to i
						set index of w to 1
						activate
						return "reused"
					end if
				end repeat
			end repeat
			open location targetURL
			activate
			return "opened"
		end tell
	end timeout
end run
]]

		---Open url in Chrome by reusing any existing localhost:6275 tab. Falls
		---back to vim.ui.open (default browser, new tab) when AppleScript fails
		---(timeout, permission denied, Chrome not running, etc.).
		local function open_url(url)
			vim.system(
				{ "osascript", "-e", chrome_script, url },
				{ text = true, timeout = 3000 },
				function(result)
					local out = result.stdout or ""
					if result.code == 0 and not out:find("no-chrome") then
						return
					end
					vim.schedule(function()
						vim.ui.open(url)
					end)
				end
			)
		end

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
									open_url(url)
								end
							)
						end, { buffer = args.buf, desc = "Preview with mo" })
					end,
				},
			},
		})
	end,
}
