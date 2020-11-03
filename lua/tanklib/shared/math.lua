function math.InRange(val, min, max)
	return val >= min and val <= max
end

function math.ClampedRemap(val, inMin, inMax, outMin, outMax)
	return math.Clamp(math.Remap(val, inMin, inMax, outMin, outMax), outMin, outMax)
end