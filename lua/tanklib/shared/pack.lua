local pack = {}

local function _Decode(str, cache)
	local callback = pack.Decoders[string.Left(str, 1)]

	if not callback then
		error("No decode type for " .. string.Left(str, 1))
	end

	return callback(string.sub(str, 2), cache)
end

pack.Pointers = {
	[TYPE_TABLE] = true,
	[TYPE_STRING] = true
}

pack.Encoders = {
	[TYPE_NIL] = function() return "?" end,
	[TYPE_BOOL] = function(val)
		return val and "t" or "f"
	end,
	[TYPE_TABLE] = function(tab)
		if IsColor(tab) then
			return pack.Encoders[TYPE_COLOR](tab)
		end

		local ret = "{"

		local cache = {}
		local index = 1

		local expected = 1
		local broken = false

		local function _HandleCache(val)
			local encoded = pack:Encode(val)

			if pack.Pointers[TypeID(val)] then
				local cached = cache[encoded]

				if cached then
					encoded = "(" .. cached .. ";"
				else
					cache[encoded] = index
					index = index + 1
				end
			end

			return encoded
		end

		for k, v in pairs(tab) do
			if not broken then
				if k == expected then
					expected = expected + 1

					ret = ret .. _HandleCache(v)
				else
					broken = true

					ret = ret .. "$"
					ret = ret .. _HandleCache(k) .. _HandleCache(v)
				end
			else
				ret = ret .. _HandleCache(k) .. _HandleCache(v)
			end
		end

		return ret .. "}"
	end,
	[TYPE_STRING] = function(str)
		local escaped, count = string.gsub(str, ";", "\\;")

		if count == 0 then
			return "'" .. escaped
		else
			return "\"" .. escaped .. "\""
		end
	end,
	[TYPE_COLOR] = function(col)
		return string.format("c%s,%s,%s,%s", col.r, col.g, col.b, col.a)
	end,
	[TYPE_VECTOR] = function(vec)
		return string.format("v%s,%s,%s", vec.x, vec.y, vec.z)
	end,
	[TYPE_ANGLE] = function(ang)
		return string.format("a%s,%s,%s", ang.p, ang.y, ang.r)
	end,
	[TYPE_NUMBER] = function(num)
		if num == 0 then
			return 0
		elseif num % 1 != 0 then
			return "n" .. num
		else
			return string.format("%s%x", num > 0 and "+" or "-", math.abs(num))
		end
	end,
	[TYPE_ENTITY] = function(ent)
		return "e" .. (IsValid(ent) and ent:EntIndex() or "#")
	end
}

pack.Decoders = {
	["?"] = function() return 1, nil end, -- Nil value
	["t"] = function() return 1, true end, -- True
	["f"] = function() return 1, false end, -- False
	["("] = function(str, cache) -- Table pointer
		local finish = string.find(str, ";")

		return finish, cache[tonumber(string.sub(str, 1, finish - 1))]
	end,
	["{"] = function(str) -- Table
		local strindex = 1
		local ret = {}

		local cache = {}

		local tabindex = 1
		local broken = false

		local function _HandleCache(val)
			local index, decoded = _Decode(val, cache)

			if pack.Pointers[TypeID(decoded)] then
				table.insert(cache, decoded)
			end

			return index, decoded
		end

		while true do
			local char = string.sub(str, strindex, strindex)

			if char == "}" then
				break
			elseif char == "$" then
				broken = true
				strindex = strindex + 1

				continue
			end

			if broken then
				local keyindex, key = _HandleCache(string.sub(str, strindex))
				local valindex, val = _HandleCache(string.sub(str, strindex + keyindex + 1))

				ret[key] = val

				strindex = strindex + keyindex + valindex + 2
			else
				local index, val = _HandleCache(string.sub(str, strindex))

				ret[tabindex] = val

				tabindex = tabindex + 1
				strindex = strindex + index + 1
			end
		end

		return strindex + 1, ret
	end,
	["'"] = function(str) -- Unescaped string
		local finish = string.find(str, ";")

		return finish, string.sub(str, 1, finish - 1)
	end,
	["\""] = function(str) -- Escaped string
		local finish = string.find(str, ";")

		return finish + 1, string.gsub(string.sub(str, 1, finish - 1), "\\;", ";")
	end,
	["c"] = function(str) -- Color
		local finish = string.find(str, ";")
		local args = string.Explode(",", string.sub(str, 1, finish - 1))

		return finish, Color(unpack(args))
	end,
	["v"] = function(str) -- Vector
		local finish = string.find(str, ";")
		local args = string.Explode(",", string.sub(str, 1, finish - 1))

		return finish, Vector(unpack(args))
	end,
	["a"] = function(str) -- Angle
		local finish = string.find(str, ";")
		local args = string.Explode(",", string.sub(str, 1, finish - 1))

		return finish, Angle(unpack(args))
	end,
	["0"] = function() -- 0
		return 1, 0
	end,
	["+"] = function(str) -- Positive integer
		local finish = string.find(str, ";")

		return finish, tonumber(string.sub(str, 1, finish - 1), 16)
	end,
	["-"] = function(str) -- Negative integer
		local finish = string.find(str, ";")

		return finish, -tonumber(string.sub(str, 1, finish - 1), 16)
	end,
	["n"] = function(str) -- Float
		local finish = string.find(str, ";")

		return finish, tonumber(string.sub(str, 1, finish - 1))
	end,
	["e"] = function(str) -- Entity
		if str[1] == "#" then
			return 2, NULL
		end

		local finish = string.find(str, ";")

		return finish, Entity(string.sub(str, 1, finish - 1))
	end
}

function pack:Encode(data)
	local callback = self.Encoders[TypeID(data)]

	if not callback then
		callback = self.Encoders[TYPE_NIL]
	end

	return callback(data) .. ";"
end

function pack:Decode(str)
	local _, res = _Decode(str)

	return res
end

TankLib.Pack = pack