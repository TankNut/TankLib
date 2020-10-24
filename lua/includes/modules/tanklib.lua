AddCSLuaFile()

TankLib = {}

local root = "TankLib"
local name = "TankLib"

local function printf(str, ...)
	print(string.format(str, ...))
end

function TankLib:LoadFolder(folder)
	local path = string.format("%s/%s/%s/", root, self.Realm, folder)
	local files = file.Find(path .. "*.lua", "LUA")

	for _, v in pairs(files) do
		printf("[%s] Loading %s file: %s/%s", name, self.Realm, folder, v)

		include(path .. v)
	end
end

function TankLib:Load()
	do -- Shared
		self.Realm = "shared"

		local files, folders = file.Find(root .. "/shared/*", "LUA")

		table.sort(files)

		for _, v in pairs(files) do
			printf("[%s] Loading shared file: %s", name, v)

			local path = root .. "/shared/" .. v

			AddCSLuaFile(path)
			include(path)
		end

		if SERVER then
			table.sort(folders)

			for _, folder in pairs(folders) do
				local path = string.format("%s/shared/%s/", root, folder)

				files = file.Find(path .. "*.lua", "LUA")

				for _, v in pairs(files) do
					AddCSLuaFile(path .. v)
				end
			end
		end
	end

	do -- Client
		self.Realm = "client"

		local files, folders = file.Find(root .. "/client/*", "LUA")

		table.sort(files)

		for _, v in pairs(files) do
			printf("[%s] Loading client file: %s", name, v)

			local path = root .. "/client/" .. v

			if CLIENT then
				include(path)
			else
				AddCSLuaFile(path)
			end
		end

		if SERVER then
			table.sort(folders)

			for _, folder in pairs(folders) do
				local path = string.format("%s/client/%s/", root, folder)

				files = file.Find(path .. "/*.lua", "LUA")

				for _, v in pairs(files) do
					AddCSLuaFile(path .. v)
				end
			end
		end
	end

	if SERVER then -- Server
		self.Realm = "server"

		local files = file.Find(root .. "/server/*.lua", "LUA")

		table.sort(files)

		for _, v in pairs(files) do
			printf("[%s] Loading server file: %s", name, v)

			include(root .. "/server/" .. v)
		end
	end

	self.Realm = nil

	printf("[%s] Finished loading", name)
end

if CLIENT then
	net.Receive("TankLib.Reload", function()
		TankLib:Load()
	end)
else
	util.AddNetworkString("TankLib.Reload")
end

concommand.Add("tanklib_reload", function()
	TankLib:Load()

	net.Start("TankLib.Reload")
	net.Broadcast()
end)

TankLib:Load()