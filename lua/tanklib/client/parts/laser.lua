local class = TankLib.Class:New("TankLib.Part.Laser", TankLib.Part.Baseclass)

function class:Initialize()
	TankLib.Part.Baseclass.Initialize(self)

	self.Beam = Material("effects/laser1")
	self.BeamColor = color_white
	self.BeamWidth = 1

	self.Sprite = Material("sprites/light_glow02_add")
	self.SpriteColor = color_white
	self.SpriteSize = 2

	self.Length = 8192
	self.Filter = {}

	self:Hook("PostDrawTranslucentRenderables")
end

function class:SetBeam(mat) self.Beam = mat end
function class:GetBeam() return self.Beam end

function class:SetBeamColor(col) self.BeamColor = col end
function class:GetBeamColor() return self.BeamColor end

function class:SetBeamWidth(width) self.BeamWidth = width end
function class:GetBeamWidth() return self.BeamWidth end

function class:SetSprite(mat) self.Sprite = mat end
function class:GetSprite() return self.Sprite end

function class:SetSpriteColor(col) self.SpriteColor = col end
function class:GetSpriteColor() return self.SpriteColor end

function class:SetSpriteSize(size) self.SpriteSize = size end
function class:GetSpriteSize() return self.SpriteSize end

function class:SetLength(length) self.Length = length end
function class:GetLength() return self.Length end

function class:SetFilter(filter) self.Filter = filter end
function class:GetFilter() return self.Filter end

function class:PostDrawTranslucentRenderables()
	TankLib.Part.Baseclass.Draw(self)

	if not self:ShouldDraw() then
		return
	end

	local pos, ang = self:GetDrawPos()

	local tr = util.TraceLine({
		start = pos,
		endpos = pos + (ang:Forward() * self.Length),
		mask = MASK_SHOT,
		filter = self.Filter
	})

	if self.BeamWidth > 0 then
		render.SetMaterial(self.Beam)
		render.DrawBeam(pos, tr.HitPos, self.BeamWidth, 0, tr.Fraction * 10, self.BeamColor)
	end

	if self.SpriteSize > 0 then
		render.SetMaterial(self.Sprite)
		render.DrawSprite(tr.HitPos, self.SpriteSize, self.SpriteSize, self.SpriteColor)
	end
end

TankLib.Part.Laser = class