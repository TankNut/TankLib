local class = TankLib.Class:New("TankLib.Part.Sprite", TankLib.Part.Baseclass)

function class:Initialize()
	TankLib.Part.Baseclass.Initialize(self)

	self.Sprite = Material("sprites/light_glow02_add")
	self.Color = color_white
	self.Size = 2

	self:Hook("PostDrawTranslucentRenderables")
end

function class:SetMaterial(mat) self.Sprite = mat end
function class:GetMaterial() return self.Sprite end

function class:SetColor(col) self.Color = col end
function class:GetColor() return self.Color end

function class:SetSize(size) self.Size = size end
function class:GetSize() return self.Size end

function class:PostDrawTranslucentRenderables()
	TankLib.Part.Baseclass.Draw(self)

	if not self:ShouldDraw() or self.Size <= 0 then
		return
	end

	local pos = self:GetDrawPos()

	render.SetMaterial(self.Sprite)
	render.DrawSprite(pos, self.Size, self.Size, self.Color)
end

TankLib.Part.Sprite = class