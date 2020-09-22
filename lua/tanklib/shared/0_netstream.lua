local netstream = TankLib.Netstream or {}

netstream.Hooks = netstream.Hooks or {}
netstream.Cache = netstream.Cache or {}

netstream.MessageLimit 	= 60000 -- 60 KB
netstream.TickLimit  	= 200000 -- 0.2 MB/s

function netstream:Split(data)
	local encoded = TankLib.Pack:Encode(data)

	if #encoded <= self.MessageLimit then
		return {{Data = encoded, Len = #encoded}}
	end

	local tab = {}
	local splits = math.ceil(#encoded / self.MessageLimit)

	for i = 1, splits do
		local buffer = string.sub(encoded, self.MessageLimit * (i - 1) + 1, self.MessageLimit * i)

		tab[i] = {Data = buffer, Len = #buffer}
	end

	return tab
end

if CLIENT then
	function netstream:Hook(name, cb)
		self.Hooks[name] = cb
		self.Cache[name] = {}
	end

	function netstream:Send(name, data)
		local payloads = self:Split(data)

		for k, v in pairs(payloads) do
			net.Start("TankLib.Netstream")
				net.WriteString(name)
				net.WriteBool(k == #payloads)
				net.WriteUInt(v.Len, 16)
				net.WriteData(v.Data, v.Len)
			net.SendToServer()
		end
	end

	net.Receive("TankLib.Netstream", function(len)
		local name = net.ReadString()
		local callback = netstream.Hooks[name]

		if not callback then
			return
		end

		local final = net.ReadBool()
		local length = net.ReadUInt(16)
		local payload = net.ReadData(length)

		local cache = netstream.Cache[name]

		table.insert(cache, payload)

		if final then
			local data = TankLib.Pack:Decode(table.concat(cache))

			table.Empty(cache)

			callback(data)
		end
	end)
else
	util.AddNetworkString("TankLib.Netstream")

	function netstream:Hook(name, cb)
		self.Hooks[name] = cb
		self.Cache[name] = {}
	end

	netstream.Queue = netstream.Queue or {}
	netstream.Rate = netstream.Rate or {}

	function netstream:GetTargets(targets)
		local result = targets

		if not targets then
			result = player.GetHumans()
		elseif TypeID(targets) == TYPE_RECIPIENTFILTER then
			result = targets:GetPlayers()
		elseif not istable(targets) then
			result = {targets}
		end

		return result
	end

	function netstream:AddToQueue(name, final, payload, targets)
		local tab = {
			Name = name,
			Final = final,
			Length = payload.Len,
			Data = payload.Data
		}

		for _, v in pairs(targets) do
			if not self.Queue[v] then
				self.Queue[v] = TankLib.Queue:New(tab)
			else
				self.Queue[v]:Push(tab)
			end
		end
	end

	function netstream:Send(name, data, targets)
		targets = self:GetTargets(targets)

		if #targets < 1 then
			return
		end

		local payloads = self:Split(data)

		for k, v in pairs(payloads) do
			self:AddToQueue(name, k == #payloads, v, targets)
		end
	end

	net.Receive("TankLib.Netstream", function(len, ply)
		local name = net.ReadString()
		local callback = netstream.Hooks[name]

		if not callback then
			return
		end

		local final = net.ReadBool()
		local length = net.ReadUInt(16)
		local payload = net.ReadData(length)

		local cache = netstream.Cache[name]

		if not cache[ply] then
			cache[ply] = {}
		end

		table.insert(cache[ply], payload)

		if final then
			local data = TankLib.Pack:Decode(table.concat(cache[ply]))

			cache[ply] = nil

			callback(data, ply)
		end
	end)

	hook.Add("Think", "TankLib.Netstream", function()
		for ply, queue in pairs(netstream.Queue) do
			if not IsValid(ply) then
				netstream.Queue[ply] = nil
				netstream.Rate[ply] = nil

				continue
			end

			if queue:Count() < 1 then
				continue
			end

			netstream.Rate[ply] = netstream.Rate[ply] or netstream.TickLimit
			netstream.Rate[ply] = math.min(netstream.Rate[ply] + (netstream.TickLimit * FrameTime()), netstream.TickLimit)

			while netstream.Rate[ply] - netstream.MessageLimit > 0 do
				local payload = queue:Pop()

				if not payload then
					break
				end

				net.Start("TankLib.Netstream")
					net.WriteString(payload.Name)
					net.WriteBool(payload.Final)
					net.WriteUInt(payload.Length, 16)
					net.WriteData(payload.Data, payload.Length)

					netstream.Rate[ply] = netstream.Rate[ply] - net.BytesWritten()
				net.Send(ply)
			end
		end
	end)
end

TankLib.Netstream = netstream