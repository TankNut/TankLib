local ready = TankLib.PlayerReady or {}

hook.Add("SetupMove", "TankLib.PlayerReady", function(ply, mv, cmd)
	if CLIENT and ply != LocalPlayer() then
		return
	end

	if cmd:IsForced() or ready[ply] then
		return
	end

	ready[ply] = true

	hook.Run("TankLib.PlayerReady", ply)

	if game.SinglePlayer() then
		TankLib.Netstream:Send("TankLib.PlayerReady")
	end
end)

if CLIENT then
	TankLib.Netstream:Hook("TankLib.PlayerReady", function()
		hook.Run("TankLib.PlayerReady", LocalPlayer())
	end)
end

local meta = FindMetaTable("Player")

function meta:IsReady()
	if CLIENT then
		if game.SinglePlayer() then
			return true
		elseif self != LocalPlayer() then
			return
		end
	end

	return ready[self]
end

function player.GetReady()
	local players = player.GetHumans()

	table.Filter(players, function(key, val)
		return val:IsReady()
	end)

	return players
end

TankLib.PlayerReady = ready