TankLib.Class.NetworkTable = TankLib.Class.NetworkTable or {}

local class = TankLib.Class:New("TankLib.Replicated")

class.Static.RegisteredNetworkVars = {}

function class.Static:RegisterNetworkVar(name, default)
	self.RegisteredNetworkVars[name] = default

	class["Get" .. name] = function(instance)
		return instance:GetNetworkVar(name)
	end

	if SERVER then
		class["Set" .. name] = function(instance, val)
			instance:SetNetworkVar(name, val)
		end
	end
end

function class.Static:New(...)
	local instance = self:Allocate()

	if SERVER then
		instance.NetworkID = table.insert(TankLib.Class.NetworkTable, instance)
	end

	instance.NetworkVars = {}
	instance:Initialize(...)

	if SERVER then
		instance:Replicate()
	end

	TankLib.Class.Instances[instance] = true -- Used for lookups and as a 'ready' indicator

	return instance
end

if CLIENT then
	function class:Replicated() -- Called when first created on the client
	end
end

-- Network vars

function class:SetNetworkVar(name, val)
	local old = self:GetNetworkVar(name)
	local new = val

	if val == nil then
		new = self.RegisteredNetworkVars[name]
	end

	self.NetworkVars[name] = val
	self:NetworkVarChanged(name, old, new)

	if SERVER and TankLib.Class.Instances[self] then -- Don't need to network stuff if we haven't replicated yet
		TankLib.Netstream:Send("TankLib.Replicated.NetworkVar", {
			ID = self.NetworkID,
			Key = name,
			Val = val
		}, player.GetReady())
	end
end

function class:GetNetworkVar(name)
	return self.NetworkVars[name] or self.RegisteredNetworkVars[name]
end

function class:NetworkVarChanged(var, old, new)
end

if SERVER then
	function class:Replicate(targets)
		if not targets then
			targets = player.GetReady()
		elseif isentity(targets) then
			targets = {targets}
		end

		if #targets > 0 then
			TankLib.Netstream:Send("TankLib.Replicated.Replicate", {
				ID = self.NetworkID,
				Class = self.Class.Name,
				Vars = self.NetworkVars
			}, targets)
		end
	end

	hook.Add("TankLib.PlayerReady", "TankLib.Replicated", function(ply)
		for instance in pairs(TankLib.Class.NetworkTable) do
			instance:Replicate(ply)
		end
	end)
end

if CLIENT then
	TankLib.Netstream:Hook("TankLib.Replicated.NetworkVar", function(data)
		local instance = TankLib.Class.NetworkTable[data.ID]

		instance:SetNetworkVar(data.Key, data.Val)
	end)

	TankLib.Netstream:Hook("TankLib.Replicated.Replicate", function(data)
		local instance = TankLib.Class:GetByName(data.Class)()

		instance.NetworkID = data.ID
		instance.NetworkVars = data.Vars

		TankLib.Class.NetworkTable[data.ID] = instance

		instance:Replicated()
	end)
end

TankLib.Class.Replicated = class