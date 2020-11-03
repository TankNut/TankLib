local class = TankLib.Class:New("TankLib.Quaternion")

-- Most of this is transcribed from wire's E2 implementation

local deg2rad = math.pi / 180
local rad2deg = 180 / math.pi

local function qmul(a, b)
	local a1, a2, a3, a4 = unpack(a)
	local b1, b2, b3, b4 = unpack(b)

	return {
		a1 * b1 - a2 * b2 - a3 * b3 - a4 * b4,
		a1 * b2 + a2 * b1 + a3 * b4 - a4 * b3,
		a1 * b3 + a3 * b1 + a4 * b2 - a2 * b4,
		a1 * b4 + a4 * b1 + a2 * b3 - a3 * b2
	}
end

function class:Initialize(...)
	local args = {...}

	for i = 1, 4 do
		self[i] = args[i] or 0
	end
end

-- Static

function class.Static:FromVector(vec)
	return class:New(0, vec.x, vec.y, vec.z)
end

function class.Static:FromAngle(ang)
	local p, y, r = ang:Unpack()

	p = p * deg2rad * 0.5
	y = y * deg2rad * 0.5
	r = r * deg2rad * 0.5

	local qp = {math.cos(p), 0, math.sin(p), 0}
	local qy = {math.cos(y), 0, 0, math.sin(y)}
	local qr = {math.cos(r), math.sin(r), 0, 0}

	return class:New(unpack(qmul(qy, qmul(qp, qr))))
end

function class.Static:FromVectors(forward, up)
	local y = up:Cross(forward):GetNormalized()

	local ang = forward:Angle()

	ang.p = math.NormalizeAngle(ang.p)
	ang.y = math.NormalizeAngle(ang.y)

	local yyaw = Vector(0, 1, 0)

	yyaw:Rotate(Angle(0, ang.y, 0))

	local roll = math.acos(math.Clamp(y:Dot(yyaw), -1, 1)) * rad2deg
	local dot = y.z

	if dot < 0 then
		roll = -roll
	end

	return self:FromAngle(Angle(ang.p, ang.y, roll))
end

function class.Static:Rotation(axis, ang)
	axis = axis:GetNormalized()
	ang = ang * deg2rad * 0.5

	return class:New(math.cos(ang), axis.x * math.sin(ang), axis.y * math.sin(ang), axis.z * math.sin(ang))
end

-- Meta

function class.__unm(self)
	return class:New(-self[1], -self[2], -self[3], -self[4])
end

function class.__add(a, b)
	if isnumber(b) then
		return class:New(a[1] + b, a[2], a[3], a[4])
	end

	return class:New(a[1] + b[1], a[2] + b[2], a[3] + b[3], a[4] + b[4])
end

function class.__sub(a, b)
	if isnumber(b) then
		return class:New(a[1] - b, a[2], a[3], a[4])
	end

	return class:New(a[1] - b[1], a[2] - b[2], a[3] - b[3], a[4] - b[4])
end

-- Methods

function class:Angle()
	local l = math.sqrt((self[1] * self[1]) + (self[2] * self[2]) + (self[3] * self[3]) + (self[4] * self[4]))

	if l == 0 then
		return Angle()
	end

	local q1 = self[1] / l
	local q2 = self[2] / l
	local q3 = self[3] / l
	local q4 = self[4] / l

	local x = Vector(
		(q1 * q1) + (q2 * q2) - (q3 * q3) - (q4 * q4),
		(2 * q3 * q2) + (2 * q4 * q1),
		(2 * q4 * q2) - (2 * q3 * q1)
	)

	local y = Vector(
		(2 * q2 * q3) - (2 * q4 * q1),
		(q1 * q1) - (q2 * q2) + (q3 * q3) - (q4 * q4)
		(2 * q2 * q1) + (2 * q3 * q4)
	)

	local ang = x:Angle()

	ang.p = math.NormalizeAngle(ang.p)
	ang.y = math.NormalizeAngle(ang.y)

	local yyaw = Vector(0, 1, 0)

	yyaw:Rotate(Angle(0, ang.y, 0))

	local roll = math.acos(math.Clamp(y:Dot(yyaw), -1, 1)) * rad2deg
	local dot = y.z

	if dot < 0 then
		roll = -roll
	end

	return Angle(ang.p, ang.y, roll)
end

TankLib.Quarternion = class