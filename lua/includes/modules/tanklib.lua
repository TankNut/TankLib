TankLib = {}

function TankLib.Load()
	local root = "TankLib"
	local name = "TankLib"

	function printf(str, ...)
		print(string.format(str, ...))
	end

	do -- Shared
		local files = file.Find(root .. "/shared/*.lua", "LUA")

		table.sort(files)

		for _, v in pairs(files) do
			printf("[%s] Loading shared file: %s", name, v)

			local path = root .. "/shared/" .. v

			AddCSLuaFile(path)
			include(path)
		end
	end

	do -- Client
		local files = file.Find(root .. "/client/*.lua", "LUA")

		table.sort(files)

		for _, v in pairs(files) do
			printf("[%s] Loading clientside file: %s", name, v)

			local path = root .. "/client/" .. v

			if CLIENT then
				include(path)
			else
				AddCSLuaFile(path)
			end
		end
	end

	if SERVER then -- Server
		local files = file.Find(root .. "/server/*.lua", "LUA")

		table.sort(files)

		for _, v in pairs(files) do
			printf("[%s] Loading server file: %s", name, v)

			local path = root .. "/server/" .. v

			include(path)
		end
	end

	printf("[%s] Finished loading", name)
end

if CLIENT then
	net.Receive("tanklib_reload", TankLib.Load)
else
	util.AddNetworkString("tanklib_reload")
end

concommand.Add("tanklib_reload", function()
	TankLib.Load()

	net.Start("tanklib_reload")
	net.Broadcast()
end)

TankLib.Load()