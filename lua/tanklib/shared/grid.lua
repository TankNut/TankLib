local class = TankLib.Class:New("TankLib.Grid")

function class:Initialize()
	local mt = {}

	for i = 1, 3 do
		mt[i] = {
			__index = function(tab, k)
				if i < 3 then
					tab[k] = setmetatable({}, mt[i + 1])

					return tab[k]
				end
			end
		}
	end

	self.Grid = setmetatable({}, mt[1])

	self.Mins = Vector()
	self.Maxs = Vector()
	self.Count = 0

	self.PendingUpdate = false
end

function class:Set(x, y, z, val)
	self.Grid[x][y][z] = val

	self.PendingUpdate = true
end

function class:Get(x, y, z)
	return self.Grid[x][y][z]
end

function class:Clear()
	self:Initialize()
end

function class:ForEach(func)
	for x, xtab in pairs(self.Grid) do
		for y, ytab in pairs(xtab) do
			for z, val in pairs(ytab) do
				func(x, y, z, val)
			end
		end
	end
end

function class:Update()
	self.PendingUpdate = false

	self.Mins = Vector(math.huge, math.huge, math.huge)
	self.Maxs = Vector(-math.huge, -math.huge, -math.huge)

	self.Count = 0

	self:ForEach(function(x, y, z)
		self.Count = self.Count + 1

		self.Mins.x = math.min(self.Mins.x, x)
		self.Mins.y = math.min(self.Mins.y, y)
		self.Mins.z = math.min(self.Mins.z, z)

		self.Maxs.x = math.max(self.Maxs.x, x)
		self.Maxs.y = math.max(self.Maxs.y, y)
		self.Maxs.z = math.max(self.Maxs.z, z)
	end)

	if self.Count == 0 then
		self.Mins = Vector()
		self.Maxs = Vector()
	end
end

function class:GetCount()
	if self.PendingUpdate then
		self:Update()
	end

	return self.Count
end

function class:GetBounds()
	if self.PendingUpdate then
		self:Update()
	end

	return self.Mins, self.Maxs
end

function class:GetSize()
	if self.PendingUpdate then
		self:Update()
	end

	if self.Count == 0 then
		return Vector()
	end

	local vec = self.Maxs - self.Mins

	vec.x = math.abs(vec.x) + 1
	vec.y = math.abs(vec.y) + 1
	vec.z = math.abs(vec.z) + 1

	return vec
end

TankLib.Grid = class