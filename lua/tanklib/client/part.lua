TRANSLATE_RELATIVE 	= 1
TRANSLATE_ABSOLUTE 	= 2

local part = {}

if TankLib.Part then
	part.Instances = TankLib.Part.Instances
	part.Children = TankLib.Part.Children
	part.Entities = TankLib.Part.Entities
else
	part.Instances = {}
	part.Children = {}
	part.Entities = {}
end

function part:Create(class, parent)
	local instance = class()
	local id = table.insert(part.Instances, instance)

	instance.ID = id
	instance.Parent = parent

	if isentity(parent) then
		self.Entities[parent] = self.Entities[parent] or {}
		self.Entities[parent][id] = instance
	else
		self.Children[parent.ID] = self.Children[parent.ID] or {}
		self.Children[parent.ID][id] = instance
	end

	return instance
end

function part:GetByID(id)
	return self.Instances[id]
end

function part:GetChildren(parent)
	if isentity(parent) then
		return self.Entities[parent]
	else
		return self.Children[parent.ID]
	end
end

function part:Clear(parent)
	if isentity(parent) then
		local children = self.Entities[parent]

		if not children then
			return
		end

		for _, v in pairs(children) do
			v:Remove()
		end

		self.Entities[parent] = nil
	else
		local children = self.Children[parent.ID]

		if not children then
			return
		end

		for _, v in pairs(children) do
			v:Remove()
		end

		self.Children[parent.ID] = nil
	end
end

function part:Draw(parent)
	local children = self:GetChildren(parent)

	if not children then
		return
	end

	for _, instance in pairs(children) do
		local drawself, drawchildren = instance:ShouldDraw()

		if drawself then
			instance:Draw()
		end

		if drawchildren then
			self:Draw(instance)
		end
	end
end

TankLib.Part = part
TankLib:LoadFolder("parts")

hook.Add("EntityRemoved", "TankLib.Part", function(ent)
	TankLib.Part:Clear(ent)
end)

hook.Add("PostPlayerDraw", "TankLib.Part", function(ply)
	TankLib.Part:Draw(ply)
end)