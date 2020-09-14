local validate = {}

validate.Filename = {
	Whitelist = "[%w_]"
}

function validate:String(str, validation)
	if validation.Min and #str < validation.Min then
		return false, string.format("Has to be at least %s characters long", validation.Min)
	end

	if validation.Max and #str > validation.Max then
		return false, string.format("Can't be longer than %s characters", validation.Max)
	end

	if validate.Whitelist or validate.Blacklist then
		local bad = {}

		for _, v in pairs(string.Explode("", str)) do
			if validate.Whitelist and not string.find(v, validate.Whitelist) then
				bad[v] = true
			elseif validate.Blacklist and string.find(v, validate.Blacklist) then
				bad[v] = true
			end
		end

		if table.Count(bad) > 0 then
			local tab = table.GetKeys(bad)

			table.sort(tab)

			return false, "Cannot contain the following characters: " .. table.concat(tab)
		end
	end

	return true
end

TankLib.Validate = validate