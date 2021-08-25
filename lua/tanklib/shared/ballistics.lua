-- Based on https://github.com/forrestthewoods/lib_fts/blob/master/code/fts_ballistic_trajectory.cs

local ballistics = {}

local function IsZero(d)
	local cutoff = 1e-9

	return d > -cutoff and d < cutoff
end

function ballistics:SolveQuadric(c1, c2, c3)
	local p = c2 / (2 * c1)
	local q = c3 / c1

	local d = p * p - q

	if IsZero(d) then
		return 1, -p
	elseif d < 0 then
		return 0
	else
		local sqrt_d = math.sqrt(d)

		return 2, sqrt_d - p, -sqrt_d - p
	end
end

function ballistics:SolveCubic(c1, c2, c3, c4)
	local num
	local o1, o2, o3

	local a = c2 / c1
	local b = c3 / c1
	local c = c4 / c1

	local sq_a = a * a

	local p = 1 / 3 * (-1 / 3 * sq_a + b)
	local q = 1 / 2 * (2 / 27 * a * sq_a - 1 / 3 * a * b + c)

	local cb_p = p * p * p
	local d = q * q + cb_p

	if IsZero(d) then
		if IsZero(q) then
			num = 1

			o1 = 0
		else
			local u = math.pow(-q, 1 / 3)

			num = 2

			o1 = 2 * u
			o2 = -u
		end
	elseif d < 0 then
		local phi = 1 / 3 * math.acos(-q / math.sqrt(-cb_p))
		local t = 2 * math.sqrt(-p)

		num = 3

		o1 = t * math.cos(phi)
		o2 = -t * math.cos(phi + math.pi / 3)
		o3 = -t * math.cos(phi - math.pi / 3)
	else
		local sqrt_d = math.sqrt(d)
		local u = math.pow(sqrt_d - q, 1 / 3)
		local v = -math.pow(sqrt_d + q, 1 / 3)

		num = 1

		o1 = u + v
	end

	local sub = 1 / 3 * a

	if num > 0 then o1 = o1 - sub end
	if num > 1 then o2 = o2 - sub end
	if num > 2 then o3 = o3 - sub end

	return num, o1, o2, o3
end

function ballistics:SolveQuartic(c1, c2, c3, c4, c5)
	local num
	local o1, o2, o3, o4

	local a = c2 / c1
	local b = c3 / c1
	local c = c4 / c1
	local d = c5 / c1

	local sq_a = a * a

	local p = -3 / 8 * sq_a + b
	local q = 1 / 8 * sq_a * a - 1 / 2 * a * b + c
	local r = -3 / 256 * sq_a * sq_a + 1 / 16 * sq_a * b - 1 / 4 * a * c + d

	if IsZero(r) then
		num, o1, o2, o3 = self:SolveCubic(1, 0, p, q)
	else
		_, o1, o2, o3 = self:SolveCubic(1, -1 / 2 * p, -r, 1 / 2 * r * p - 1 / 8 * q * q)

		local z = o1

		local u = z * z - r
		local v = 2 * z - p

		if IsZero(u) then
			u = 0
		elseif u > 0 then
			u = math.sqrt(u)
		else
			return 0
		end

		if IsZero(v) then
			v = 0
		elseif v > 0 then
			v = math.sqrt(v)
		else
			return 0
		end

		num, o1, o2 = self:SolveQuadric(1, q < 0 and -v or v, z - u)

		local co1 = 1
		local co2 = q < 0 and v or -v
		local co3 = z + u

		if num == 0 then
			local old = num

			num, o1, o2 = self:SolveQuadric(co1, co2, co3)
			num = num + old
		end

		if num == 1 then
			local old = num

			num, o2, o3 = self:SolveQuadric(co1, co2, co3)
			num = num + old
		end

		if num == 2 then
			local old = num

			num, o3, o4 = self:SolveQuadric(co1, co2, co3)
			num = num + old
		end
	end

	local sub = 1 / 4 * a

	if num > 0 then o1 = o1 - sub end
	if num > 1 then o2 = o2 - sub end
	if num > 2 then o3 = o3 - sub end
	if num > 3 then o3 = o3 - sub end

	return num, o1, o2, o3, o4
end

function ballistics:GetRange(vel, gravity, height)
	local ang = math.rad(45)
	local cos = math.cos(ang)
	local sin = math.sin(ang)

	return (vel * cos / gravity) * (vel * sin + math.sqrt(vel^2 * sin^2 + 2 * gravity * height))
end

function ballistics:SolveStatic(origin, target, vel, gravity)
	local diff = target - origin
	local diff2 = Vector(diff.x, diff.y, 0)

	local dist = diff2:Length()

	local gx = gravity * dist

	local root = vel^4 - gravity * (gravity * dist * dist + 2 * diff.z * vel^2)

	if root < 0 then
		return 0
	end

	root = math.sqrt(root)

	local low = math.atan2(vel2 - root, gx)
	local high = math.atan(vel2 + root, gx)

	local solutions = (low != high) and 2 or 1

	local dir = diff2:GetNormalized()

	low = dir * math.cos(low) * vel + Vector(0, 0, 1) * math.sin(low) * vel
	high = dir * math.cos(high) * vel + Vector(0, 0, 1) * math.sin(high) * vel

	return solutions, low, high
end

function ballistics:SolveMoving(origin, target, targetvel, vel, gravity)
	local h = target.x - origin.x
	local j = target.y - origin.y
	local k = target.z - origin.z

	local l = -0.5 * gravity

	local c1 = l * l
	local c2 = 2 * targetvel.z * l
	local c3 = targetvel.z * targetvel.z + 2 * k * l - vel * vel + targetvel.x * targetvel.x + targetvel.y * targetvel.y
	local c4 = 2 * k * targetvel.z + 2 * h * targetvel.x + 2 * j * targetvel.y
	local c5 = k * k + h * h + j * j

	local _, o1, o2, o3, o4 = self:SolveQuartic(c1, c2, c3, c4, c5)
	local tab = {o1, o2, o3, o4}

	table.sort(tab)

	local s1, s2
	local num = 0

	for _, v in pairs(tab) do
		if v <= 0 then
			continue
		end

		num = num + 1

		if not s1 then
			s1 = Vector(
				(h + targetvel.x * v) / v,
				(j + targetvel.y * v) / v,
				(k + targetvel.z * v - l * v * v) / v
			)
		elseif not s2 then
			s2 = Vector(
				(h + targetvel.x * v) / v,
				(j + targetvel.y * v) / v,
				(k + targetvel.z * v - l * v * v) / v
			)
		else
			break
		end
	end

	return num, s1, s2
end

function ballistics:SolveStaticLateral(origin, target, vel, height)
	local diff = target - origin
	local diff2 = Vector(diff.x, diff.y, 0)

	local dist = diff2:Length()

	if dist == 0 then
		return false
	end

	local time = dist / vel
	local vec = diff2:GetNormalized() * vel

	local a = origin.z
	local b = math.max(origin.z, target.z) + height
	local c = target.z

	local gravity = -4 * (a - 2 * b + c) / (time * time)

	vec.z = -(3 * a - 4 * b + c) / time

	return true, vec, gravity
end

function ballistics:SolveMovingLateral(origin, target, targetvel, vel, height)
	local diff = target - origin
	local diff2 = Vector(diff.x, diff.y, 0)

	local targetvel2 = Vector(targetvel.x, targetvel.y, 0)

	local c1 = targetvel2:Dot(targetvel2) - vel * vel
	local c2 = 2 * diff2:Dot(targetvel2)
	local c3 = diff2:Dot(diff2)

	local num, o1, o2 = self:SolveQuadric(c1, c2, c3)

	local v1 = num > 0 and o1 > 0
	local v2 = num > 1 and o2 > 0

	local time

	if not v1 and not v2 then
		return false
	elseif v1 and v2 then
		time = math.min(o1, o2)
	else
		time = v1 and o1 or o2
	end

	local impact = target + (targetvel * time)
	local dir = impact - origin

	local vec = Vector(dir.x, dir.y, 0):GetNormalized() * vel

	local a = origin.z
	local b = math.max(origin.z, impact.z) + height
	local c = impact.z

	local gravity = -4 * (a - 2 * b + c) / (time * time)

	vec.z = -(3 * a - 4 * b + c) / time

	return true, vec, gravity
end

function ballistics:ToSpread(degrees)
	return math.rad(degrees * 0.5)
end

function ballistics:ToDegrees(spread)
	return math.deg(spread) * 2
end

local csgo = 12 -- Per https://old.reddit.com/r/GlobalOffensive/comments/2eq73n/gun_accuracy/ck2cbrq/: 30 cm ≈ 12 units

-- Diameter is the diameter of the target you want to hit in hammer units
function ballistics:GetEffectiveRange(degrees, diameter)
	if diameter then
		diameter = diameter / 0.75 -- Convert to inches
	else
		diameter = csgo
	end

	local MOA = degrees * 60 -- Convert to minute of angle, 1 MOA = 1/60th of a degree
	local yards = (diameter * 100) / MOA

	return yards * 27 -- Yards to inches -> x36, inches to units -> x0.75, 0.75 * 36 = 27
end

function ballistics:GetRequiredSpread(range, diameter)
	if diameter then
		diameter = diameter / 0.75 -- Convert to inches
	else
		diameter = csgo
	end
	
	local yards = (range / 0.75) / 36
	local MOA = (diameter * 100) / yards
	
	return MOA / 60
end

TankLib.Ballistics = ballistics
