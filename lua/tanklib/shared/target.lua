local target = {
	Fallback = function(ent)
		local low = ent:WorldSpaceCenter() - (ent:WorldSpaceCenter() - ent:GetPos()) * 0.25
		local high = ent:EyePos()

		local delta = high - low

		return low + delta * 0.5
	end,
	Functions = {}
}

local function headcrab(ent)
	return ent:GetPos() + Vector(0, 0, 6)
end

target.Functions["npc_headcrab"] = headcrab
target.Functions["npc_headcrab_fast"] = headcrab
target.Functions["npc_headcrab_black"] = headcrab
target.Functions["npc_headcrab_poison"] = headcrab

local function antlion(ent)
	local index = ent:LookupBone("Antlion.Body_Bone")
	local pos = ent:GetBonePosition(index)

	return pos
end

target.Functions["npc_antlion"] = antlion
target.Functions["npc_antlionworker"] = antlion

function target:Get(ent)
	return self.Functions[ent:GetClass()] and self.Functions[ent:GetClass()](ent) or self.Fallback(ent)
end

TankLib.Target = target