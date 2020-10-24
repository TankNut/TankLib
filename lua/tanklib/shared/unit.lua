local unit = {}

local function convert(tab, val, from, to)
	val = isnumber(tab[from]) and val * tab[from] or tab[from].From(val)

	return isnumber(tab[to]) and val / tab[to] or tab[to].To(val)
end

unit.Length = { -- Default unit: Meter
	-- Source
	u = 0.01905,
	su = 0.3048, -- Skybox unit
	cu = 0.2286, -- Character unit
	-- Metric
	mm = 0.001,
	cm = 0.01,
	m = 1,
	km = 1000,
	-- Imperial
	["in"] = 0.0254,
	ft = 0.3048,
	yd = 0.9144,
	mi = 1609.344
}

function unit:ConvertLength(val, from, to)
	return convert(self.Length, val, from, to)
end

unit.Temperature = { -- Default unit: Kelvin
	-- Metric
	C = {
		From = function(val) return val + 273.15 end,
		To = function(val) return val - 273.15 end
	},
	K = 1,
	-- Imperial
	F = {
		From = function(val) return (val - 32) * (5 / 9) + 273.15 end,
		To = function(val) return (val - 273.15) * (9 / 5) + 32 end
	}
}

function unit:ConvertTemperature(val, from, to)
	return convert(self.Temperature, val, from, to)
end

unit.Mass = { -- Default unit: Kilogram
	-- Metric
	mg = 0.000001,
	g = 0.001,
	kg = 1,
	t = 1000,
	-- Imperial
	lb = 0.45359237
}

function unit:ConvertMass(val, from, to)
	return convert(self.Mass, val, from, to)
end

TankLib.Unit = unit