function surface.FontExists(font)
	local ok = pcall(surface.SetFont, font)

	return ok
end