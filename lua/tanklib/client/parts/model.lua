local class = TankLib.Class:New("TankLib.Part.Model", TankLib.Part.Baseclass)

function class:Initialize()
	TankLib.Part.Baseclass.Initialize(self)

	self.Center = false

	self.Model = ""
	self.Skin = 0

	self.Bonemerge = false

	self:Hook("Think")
end

function class:Cleanup()
	TankLib.Part.Baseclass.Cleanup(self)

	self.Entity:Remove()
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

function class:CreateEntity()
	if IsValid(self.Entity) then
		self.Entity:Remove()
	end

	self.Entity = ClientsideModel(self.Model)
	self.Entity:SetNoDraw(false)

	self.Entity:SetSkin(self.Skin)

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

function class:GetOrigin()
	if self.Center and IsValid(self.Entity) then
		return LerpVector(0.5, self.Entity:GetModelBounds()), angle_zero
	end

	return TankLib.Part.Baseclass.GetOrigin(self)
end

function class:GetRenderOrigin()
	if self.Bonemerge then
		return self.Parent:WorldSpaceCenter(), self.Parent:GetAngles() -- WorldSpaceCenter instead of GetPos to fix some lighting issues where the csent's lighting origin ends up out of bounds
	end

	return TankLib.Part.Baseclass.GetRenderOrigin(self)
end

function class:GetBonePos(bone)
	local pos, ang = LocalToWorld(-self:GetOrigin(), angle_zero, self:GetRenderPos())

	if IsValid(self.Entity) then
		self.Entity:SetPos(pos)
		self.Entity:SetAngles(ang)

		self.Entity:SetupBones()

		local id = self.Entity:LookupBone(bone)

		return self.Entity:GetBonePosition(id)
	end

	return pos, ang
end

function class:Draw()
	TankLib.Part.Baseclass.Draw(self)

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