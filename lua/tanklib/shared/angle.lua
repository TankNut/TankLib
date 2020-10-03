local angle = FindMetaTable("Angle")

function angle:InRange(min, max)
	return math.InRange(self.p, min.p, max.p) and math.InRange(self.y, min.y, max.y) and math.InRange(self.r, min.r, max.r)
end