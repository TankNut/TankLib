local class = TankLib.Class:New("TankLib.Part.Baseclass")

class:Include(TankLib.Class.Mixins.Hook)

function class:Initialize()
	self.Valid = true

	self.Active = true
	self.Hidden = false

	self.Pos = vector_origin
	self.Ang = angle_zero

	self.Bone = false

	self.Translate = {TRANSLATE_RELATIVE, TRANSLATE_RELATIVE}
	self.Debug = false
end

function class:Remove()
	self:Cleanup()

	TankLib.Part:Clear(self)

	TankLib.Part:GetChildren(self.Parent)[self.ID] = nil
	TankLib.Part.Instances[self.ID] = nil
end

function class:IsValid()
	return self.Valid
end

function class:Cleanup()
	self.Valid = false -- Cleans up all hooks
end

function class:GetID() return self.ID end
function class:GetParent() return self.Parent end

function class:SetActive(active) self.Active = active end
function class:GetActive() return self.Active end

function class:SetHidden(hidden) self.Hidden = hidden end
function class:GetHidden() return self.Hidden end

function class:SetPos(pos) self.Pos = pos end
function class:GetPos() return self.Pos end

function class:SetAngles(ang) self.Ang = ang end
function class:GetAngles() return self.Ang end

function class:SetTranslation(pos, ang) self.Translate = {pos, ang} end
function class:GetTranslation() return unpack(self.Translate) end

function class:SetBone(bone) self.Bone = bone end
function class:GetBone() return self.Bone end

function class:SetDebug(bool) self.Debug = bool end
function class:GetDebug() return self.Debug end

function class:GetBasePosition() -- Our position on our parent
	local parent = self:GetParent()
	local bone = self:GetBone()

	if isentity(parent) then
		if bone then
			return parent:GetBonePosition(parent:LookupBone(bone))
		else
			return parent:GetPos(), parent:GetAngles()
		end
	else
		return parent:GetBonePosition(bone)
	end
end

function class:GetBonePosition(bone)
	return self:GetRenderPos()
end

function class:GetRenderPos()
	local pos, ang = self:GetBasePosition()
	local relative = {LocalToWorld(self.Pos, self.Ang, pos, ang)}
	local modes = self.Translate

	if modes[1] == TRANSLATE_RELATIVE then
		pos = relative[1]
	elseif modes[1] == TRANSLATE_ABSOLUTE then
		pos = pos + self.Pos
	end

	if modes[2] == TRANSLATE_RELATIVE then
		ang = relative[2]
	elseif modes[2] == TRANSLATE_ABSOLUTE then
		ang = ang + self.Ang
	end

	return pos, ang
end

function class:ShouldDraw()
	if not self.Active then
		return false, false
	end

	if isentity(self.Parent) then
		if self.Parent:GetNoDraw() or self.Parent:IsDormant() then
			return false, false
		elseif self.Parent == LocalPlayer() and not self.Parent:ShouldDrawLocalPlayer() then
			return false, false
		end
	end

	return not self.Hidden, true
end

function class:SetTranslationMode(pos, ang)
	self.TranslationMode = {pos, ang}
end

function class:Draw()
	if self.Debug then
		local pos, ang = self:GetRenderPos()

		render.DrawLine(pos, pos + (ang:Forward() * 5), Color(255, 0, 0), true)
		render.DrawLine(pos, pos + (ang:Right() * 5), Color(0, 255, 0), true)
		render.DrawLine(pos, pos + (ang:Up() * 5), Color(0, 0, 255), true)
	end
end

TankLib.Part.Baseclass = class