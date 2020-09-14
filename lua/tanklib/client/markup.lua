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

	Tags[string.lower(name)] = tab
end

function class.Static:SetDefaults(data)
	for k in pairs(keys) do
		if data[k] then
			keys[k] = data[k]
		end
	end
end

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

local function _ProcessMatch(blocks, str)
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

local function _ProcessMatches(blocks, ...)
	for _, v in pairs({...}) do
		_ProcessMatch(blocks, v)
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

function class:Initialize(width, height, blocks)
	self.Width = width
	self.Height = height
	self.Blocks = blocks
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
	end
end