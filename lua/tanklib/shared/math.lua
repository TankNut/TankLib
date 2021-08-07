function math.InRange(val, min, max)
	return val >= min and val <= max
end

function math.ClampedRemap(val, inMin, inMax, outMin, outMax)
	return math.Clamp(math.Remap(val, inMin, inMax, outMin, outMax), outMin, outMax)
end

function math.IsHuge(val)
	if isnumber(val) then
		return val == -math.huge or val == math.huge
	end

	return math.IsHuge(val[1]) or math.IsHuge(val[2]) or math.IsHuge(val[3])
end