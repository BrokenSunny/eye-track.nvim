local function iter_line(cursor_row, topline, botline, callback)
	local top_break
	local bot_break
	local count = 0

	while true do
		count = count + 1
		if bot_break and top_break then
			break
		end

		if cursor_row - count >= topline then
			callback(cursor_row - count)
		else
			top_break = true
		end

		if cursor_row + count <= botline then
			callback(cursor_row + count)
		else
			bot_break = true
		end
	end
end

local function main(options)
	local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]

	local topline = wininfo.topline
	local botline = wininfo.botline
	if options.range and type(options.range) == "function" then
		local range = options.range({ topline = topline, botline = botline })
		topline = range[1]
		botline = range[2]
	end

	local virt_col = vim.fn.virtcol(".")
	local cursor = vim.api.nvim_win_get_cursor(0)

	--- @type EyeTrack.LabelSpec[]
	local labels = {}
	---@diagnostic disable-next-line: undefined-field
	local virtualedit = vim.opt_local.virtualedit:get()[1]

	local callback
	if virtualedit == "all" then
		callback = function(row)
			local _col = vim.fn.virtcol2col(vim.api.nvim_get_current_win(), row, virt_col) - 1
			if _col < 0 then
				_col = 0
			end
			local col = virt_col - wininfo.leftcol - 1
			table.insert(labels, {
				line = row - 1,
				virt = true,
				col = col,
				data = {
					row = row,
					col = _col,
					offset = row - cursor[1],
					topline = topline,
					botline = botline,
				},
			})
		end
	elseif virtualedit == "none" then
		callback = function(row)
			local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
			local _col = vim.fn.virtcol2col(vim.api.nvim_get_current_win(), row, virt_col) - 1
			if _col < 0 then
				_col = 0
			end
			local col = virt_col - 1
			if vim.fn.strdisplaywidth(line) < virt_col then
				col = vim.fn.strdisplaywidth(line) - 1
			end
			col = col - wininfo.leftcol
			if col < 0 then
				col = -1
			end
			local label = {
				line = row - 1,
				virt = true,
				col = col,
				data = {
					row = row,
					col = _col,
					offset = row - cursor[1],
					topline = topline,
					botline = botline,
				},
			}
			table.insert(labels, label)
		end
	end
	iter_line(cursor[1], topline, botline, callback)
	local Layer = require("eye-track.core.layer")
	require("eye-track.core").main(labels, {
		start = function()
			Layer.draw()
		end,
		finish = function()
			Layer.clear()
		end,
		matched = options.matched,
	})
end

return main
