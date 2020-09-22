function table.Filter(tab, callback)
	local pointer = 1

	for i = 1, #tab do
		if callback(i, tab[i]) then
			if i != pointer then
				tab[pointer] = tab[i]
				tab[i] = nil
			end

			pointer = pointer + 1
		else
			tab[i] = nil
		end
	end
end

function table.GetLookup(tab)
	local ret = {}

	for _, v in pairs(tab) do
		ret[v] = true
	end

	return ret
end

function table.GetUnique(tab)
	local lookup = {}
	local ret = {}

	for _, v in pairs(tab) do
		if not lookup[v] then
			lookup[v] = true

			table.insert(ret, v)
		end
	end

	return ret
end