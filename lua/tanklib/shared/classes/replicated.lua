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

if CLIENT then
	function class.Static:New(id, vars)
		local instance = self:Allocate()

		instance.NetworkID = id
		instance.NetworkVars = vars

		instance:Initialize()

		TankLib.Class.Instances[instance] = true
		TankLib.Class.NetworkTable[id] = instance

		return instance
	end
else
	function class.Static:New(...)
		local instance = self:Allocate()

		instance.NetworkID = table.insert(TankLib.Class.NetworkTable, instance)
		instance.NetworkVars = {}

		instance:Initialize(...)
		instance:Replicate()

		TankLib.Class.Instances[instance] = true -- Used as a 'ready' indicator
		TankLib.Class.NetworkTable[instance.NetworkID] = instance

		return instance
	end
end

-- Network vars

function class:SetNetworkVar(name, val)
	local old = self:GetNetworkVar(name)
	local new = val

	if val == nil then
		new = self.Class.RegisteredNetworkVars[name]
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
	return self.NetworkVars[name] or self.Class.RegisteredNetworkVars[name]
end

function class:NetworkVarChanged(var, old, new)
end

function class:Destroy()
	if SERVER then
		TankLib.Class.NetworkTable[self.NetworkID] = nil

		TankLib.Netstream:Send("TankLib.Replicated.Destroy", self.NetworkID)
	end
end

if SERVER then
	function class:Replicate(targets)
		if not targets then
			targets = player.GetReady()
		end

		TankLib.Netstream:Send("TankLib.Replicated.Replicate", {
			ID = self.NetworkID,
			Class = self.Class.Name,
			Vars = self.NetworkVars
		}, targets)
	end

	function class:RemoteCall(func, targets, ...)
		if not targets then
			targets = player.GetReady()
		end

		TankLib.Netstream:Send("TankLib.Replicated.RPC", {
			ID = self.NetworkID,
			Func = self.NetworkVars,
			Args = {...}
		}, targets)
	end

	hook.Add("TankLib.PlayerReady", "TankLib.Replicated", function(ply)
		for instance in pairs(TankLib.Class.NetworkTable) do
			instance:Replicate(ply)
		end
	end)
end

if CLIENT then
	TankLib.Netstream:Hook("TankLib.Replicated.Destroy", function(id)
		TankLib.Class.NetworkTable[id]:Destroy()
	end)

	TankLib.Netstream:Hook("TankLib.Replicated.Replicate", function(data)
		TankLib.Class:GetByName(data.Class)(data.ID, data.Vars)
	end)

	TankLib.Netstream:Hook("TankLib.Replicated.NetworkVar", function(data)
		TankLib.Class.NetworkTable[data.ID]:SetNetworkVar(data.Key, data.Val)
	end)

	TankLib.Netstream:Hook("TankLib.Replicated.RPC", function(data)
		TankLib.Class.NetworkTable[data.ID][data.Func](instance, unpack(data.Args))
	end)
end

TankLib.Class.Replicated = class