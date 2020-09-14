local class = TankLib.Class("TankLib.Markup")

class.Static.Tags = {}

local keys = {
	Color = color_white,
	Font = "DermaDefault",
	Outline = 0,
	Callback = false
}

function class.Static:RegisterTag(name, data)
	local tab = {}

	for k in pairs(keys) do
		if data[k] then
			tab[k] = data[k]
		end
	end

	self.Tags[string.lower(name)] = tab
end

function class.Static:SetDefaults(data)
	for k in pairs(keys) do
		if data[k] then
			keys[k] = data[k]
		end
	end
end

local blocks = {}
local stack = {}

for k in pairs(keys) do
	stack[k] = {}
end

local function _ProcessStack(tag, args)
	if tag == "reset" then
		for k in pairs(keys) do
			stack[k] = {keys[k]}
		end

		return
	end

	local tags = class.Static.Tags

	if not tags[tag] and not tags[string.sub(tag, 2)] then
		return
	end

	if tag[1] == "/" then
		for k in pairs(tags[string.sub(tag, 2)]) do
			if #stack[k] == 1 then
				continue
			end

			table.remove(stack[k])
		end
	else
		for k, v in pairs(tags[tag]) do
			local tab = stack[k]

			table.insert(tab, (isfunction(v) and k != "Callback") and v(tab[#tab], args) or v)
		end
	end
end

local function _ProcessMatch(str)
	if not str or str == "" then
		return
	end

	if str[1] == "<" then
		string.gsub(str, "<([/%a]*)=?([^>]*)", _ProcessStack)
	else
		local block = table.Copy(blocks[#blocks]) or {}

		for k in pairs(keys) do
			local tab = stack[k]

			block[k] = tab[#tab]
		end

		block.Text = str

		table.insert(blocks, block)
	end
end

local function _ProcessMatches(...)
	for _, v in pairs({...}) do
		_ProcessMatch(v)
	end
end

local function _GetLastSpace(str)
	local pos = #str

	for i = 1, #str do
		if string.sub(str, i, i) == " " then
			pos = i
		end
	end

	return pos
end

local function _Parse(unparsed, maxwidth)
	local forced = utf8.force(unparsed)

	for k, v in pairs(keys) do
		stack[k] = v
	end

	if not string.find(forced, "<") then
		forced = forced .. "<nop>"
	end

	string.gsub(forced, "([^<>]*)(<[^>]+.)([^<>]*)", _ProcessMatches)

	local offset = {x = 0, y = 0}
	local xmax = 0
	local size = 0
	local space = false

	local processed = {}
	local maxheight = {}

	local lineheight = 0

	for k, blk in pairs(blocks) do
		if not surface.FontExists(blk.Font) then
			local prev = blocks[k - 1]

			blk.Font = prev and prev.Font or keys.Font
		end

		surface.SetFont(blk.Font)

		local max = 0
		local height = 0
		local str = ""

		local function AddBlock(w, h)
			local block = {
				w = w,
				h = h,
				x = offset.x,
				y = offset.y
			}

			for key, v in pairs(blk) do
				block[key] = v
			end

			block.Text = str
			block.Space = space

			table.insert(processed, block)
		end

		blk.Text = string.gsub(blk.Text, "&gt;", ">")
		blk.Text = string.gsub(blk.Text, "&lt;", "<")

		for pos, code in utf8.codes(blk.Text) do
			local char = utf8.char(code)

			if char == "\n" then
				if height == 0 then
					height = lineheight
					max = lineheight
				else
					lineheight = height
				end

				if #str > 0 then
					local w, h = surface.GetTextSize(str)

					AddBlock(w, h)

					xmax = math.max(xmax, offset.x + w)

					max = math.max(max, h)
					maxheight[offset.y] = max
				end

				offset.x = 0
				size = 0
				offset.y = offset.y + max
				height = 0
				str = ""
				max = 0
			else
				local x, y = surface.GetTextSize(char)

				if not x then
					return
				end

				if (maxwidth and maxwidth > x) and (offset.x + size + x >= maxwidth) then
					-- Line is too long, cut it
					local last = _GetLastSpace(str)

					if last == #str and last > 0 then
						local start = utf8.offset(str, 0, last)

						char = string.match(str, utf8.charpattern, start) .. char
						pos = utf8.offset(str, 1, start)

						str = string.sub(str, 1, start - 1)
					else
						-- Can't find a space, cut off at the last character
						char = string.sub(str, last + 1) .. char
						pos = last + 1

						str = string.sub(str, 1, last)
					end

					-- Clear excess spaces from the start of the next line
					local m = 1 

					space = false

					while string.sub(char, m, m) == " " do
						m = m + 1
						space = true
					end

					char = string.sub(char, m)

					local w, h = surface.GetTextSize(str)

					max = math.max(max, h)
					maxheight[y] = max
					lineheight = max

					AddBlock(w, height)

					xmax = math.max(xmax, offset.x + w)

					offset.x = 0
					size = 0
					x, y = surface.GetTextSize(char)
					offset.y = offset.y + max
					height = 0
					str = ""
					max = 0
				end

				str = str .. char

				height = y
				size = size + x

				max = math.max(max, y)
				maxheight[offset.y] = max
			end
		end

		if #str > 0 then
			local width = surface.GetTextSize(str)

			AddBlock(width, height)

			offset.x = offset.x + width
			xmax = math.max(xmax, offset.x)
			lineheight = height
		end

		size = 0
	end

	local total = 0

	for _, block in pairs(processed) do
		block.Height = maxheight[block.y]
		total = math.max(total, block.y + block.Height)
	end

	return xmax, total, processed
end

function class:Initialize(unparsed, maxwidth)
	local width, height, data = _Parse(unparsed, maxwidth)

	self.Width = width
	self.Height = height
	self.Blocks = data
end

function class:GetWidth()
	return self.Width
end

function class:GetHeight()
	return self.Height
end

function class:GetSize()
	return self:GetWidth(), self:GetHeight()
end

function class:Draw(offsetx, offsety, halign, valign, alpha)
	for _, block in pairs(self.Blocks) do
		surface.SetFont(block.Font)

		local w, h = surface.GetTextSize(block.Text)
		local x = offsetx

		if halign == TEXT_ALIGN_CENTER then
			x = x - (self:GetWidth() * 0.5)
		elseif halign == TEXT_ALIGN_RIGHT then
			x = x - w + self:GetWidth()
		end

		x = x + block.x

		local y = offsety + (block.Height - block.h) + block.y

		if valign == TEXT_ALIGN_CENTER then
			y = y - (self:GetHeight() * 0.5)
		elseif valign == TEXT_ALIGN_RIGHT then
			y = y - h + self:GetHeight()
		end

		local a = alpha or 255

		if block.Outline == true then
			surface.SetTextColor(0, 0, 0, a)

			surface.SetTextPos(x + 1, y + 1)
			surface.DrawText(block.Text)
		elseif block.Outline > 0 then
			local width = block.Outline
			local step = math.max((width * 2) / 3, 1)

			surface.SetTextColor(0, 0, 0, a)

			for _x = -width, width, step do
				for _y = -width, width, step do
					surface.SetTextPos(x + _x, y + _y)
					surface.DrawText(block.Text)
				end
			end
		end

		if block.Callback then
			block:Callback()
		end

		surface.SetTextColor(ColorAlpha(block.Color, a))
		surface.SetTextPos(x, y)
		surface.DrawText(block.Text)
	end
end

function class:Print()
	local args = {}
	local lastColor

	for _, block in pairs(self.Blocks) do
		if block.Callback then
			block:Callback(true)
		end

		if block.Color != args[lastColor] then
			lastColor = table.insert(args, block.Color)
		end

		local text = block.Text

		if block.Space then
			text = text .. " "
		end

		table.insert(args, text)
	end

	table.insert(args, "\n")

	MsgC(unpack(args))
end

function class:GetString()
	local args = {}

	for _, block in pairs(self.Blocks) do
		local text = block.Text

		if block.Space then
			text = text .. " "
		end

		table.insert(args, text)
	end

	return table.concat(args)
end

TankLib.Markup = class