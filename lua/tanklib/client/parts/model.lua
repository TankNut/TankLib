local class = TankLib.Class:New("TankLib.Part.Model", TankLib.Part.Baseclass)

function class:Initialize()
	TankLib.Part.Baseclass.Initialize(self)

	self.Center = false

	self.Model = ""
	self.Skin = 0

	self.Scale = 1

	self.Bonemerge = false

	self:Hook("Think")
end

function class:Cleanup()
	TankLib.Part.Baseclass.Cleanup(self)

	if IsValid(self.Entity) then
		self.Entity.RenderOverride = nil
		self.Entity:SetNoDraw(true)
		self.Entity:Remove()
	end
end

function class:GetEntity() return self.Entity end

function class:SetModel(mdl) self.Model = mdl self:CreateEntity() end
function class:GetModel() return self.Model end

function class:SetSkin(num) self.Skin = num if IsValid(self.Entity) then self.Entity:SetSkin(num) end end
function class:GetSkin() return self.Skin end

function class:SetBonemerge(bool) assert(isentity(self.Parent), "Bonemerge is not supported on non-entity parents") self.Bonemerge = bool self:CreateEntity() end
function class:GetBonemerge() return self.Bonemerge end

function class:SetCentered(bool) self.Center = bool end
function class:GetCentered() return self.Center end

function class:SetScale(scale) self.Scale = scale self:CreateEntity() end
function class:GetScale() return self.Scale end

function class:CreateEntity()
	if IsValid(self.Entity) then
		self.Entity:Remove()
	end

	self.Entity = ClientsideModel(self.Model)
	self.Entity:SetNoDraw(false)

	self.Entity:SetSkin(self.Skin)

	self.Entity:SetModelScale(self.Scale)

	if self.Bonemerge then
		self.Entity:SetParent(self.Parent)
		self.Entity:AddEffects(bit.bor(EF_BONEMERGE, EF_BONEMERGE_FASTCULL, EF_PARENT_ANIMATES))
	end

	self.Entity.RenderOverride = function(ent)
		if not self:ShouldDraw() then
			ent:DestroyShadow()

			return
		end

		local pos, ang = self:GetDrawPos()

		ent:SetPos(pos)
		ent:SetAngles(ang)

		ent:SetRenderOrigin(pos)
		ent:SetRenderAngles(ang)

		ent:SetupBones()
		ent:CreateShadow()
		ent:DrawModel()
	end

	local pos, ang = self:GetDrawPos()

	self.Entity:SetPos(pos)
	self.Entity:SetAngles(ang)
end

function class:Think()
	if not IsValid(self.Entity) and #self.Model > 0 then
		self:CreateEntity()
	end
end

function class:GetBonePosition(bone)
	local pos, ang = TankLib.Part.Baseclass.GetBonePosition(self, bone)

	if IsValid(self.Entity) and self.Bone then
		self.Entity:SetPos(pos)
		self.Entity:SetAngles(ang)

		self.Entity:SetupBones()

		return self.Entity:GetBonePosition(self.Entity:LookupBone(bone))
	end

	return pos, ang
end

function class:GetDrawPos()
	local pos, ang = self:GetRenderPos()

	if self.Bonemerge then
		return self.Parent:WorldSpaceCenter(), self.Parent:GetAngles()
	elseif self.Center and IsValid(self.Entity) then
		return LocalToWorld(-LerpVector(0.5, self.Entity:GetModelBounds()), angle_zero, pos, ang)
	end

	return pos, ang
end

function class:Draw()
	local ent = self.Entity

	if not IsValid(ent) then
		return
	end

	if self.Bonemerge and ent:GetParent() != self.Parent then
		ent:SetParent(self.Parent)
	end

	local pos, ang = self:GetDrawPos()

	ent:SetPos(pos)
	ent:SetAngles(ang)

	ent:SetRenderOrigin(pos)
	ent:SetRenderAngles(ang)
end

TankLib.Part.Model = class