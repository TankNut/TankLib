local meta = FindMetaTable("PhysObj")

function meta:ApplyAngForce(force)
	if math.IsHuge(force) then
		return
	end

	local ang = self:GetAngles()

	local up = ang:Up()
	local left = -ang:Right()
	local forward = ang:Forward()

	if force.p != 0 then
		local pitch = up * (force.p * 0.5)

		self:ApplyForceOffset(forward, pitch)
		self:ApplyForceOffset(-forward, -pitch)
	end

	if force.y != 0 then
		local yaw = forward * (force.y * 0.5)

		self:ApplyForceOffset(left, yaw)
		self:ApplyForceOffset(-left, -yaw)
	end

	if force.r != 0 then
		local roll = left * (force.r * 0.5)

		self:ApplyForceOffset(up, roll)
		self:ApplyForceOffset(-up, -roll)
	end
end

function meta:ApplyEasyAngForce(force, damping)
	local angVel = self:GetAngleVelocity()
	local damped = force - Angle(angVel.y, angVel.z, angVel.x) * damping

	local inertia = self:GetInertia()

	inertia = Angle(inertia.y, inertia.z, inertia.x)

	self:ApplyAngForce(Angle(damped.p * inertia.p, damped.y * inertia.y, damped.r * inertia.r))
end