-- Based on https://github.com/kikito/middleclass 4.1.1

local class = TankLib.Class or {
	NetworkTable = {},
	Instances = setmetatable({}, {
		__mode = "k"
	}),
	Classes = {},
	Mixins = {}
}

local function _CreateIndexWrapper(aClass, func)
	if not func then
		return aClass.__InstanceDictionary
	else
		return function(self, name)
			local val = aClass.__InstanceDictionary[name]

			if val then
				return val
			elseif isfunction(func) then
				return func(self, name)
			else
				return func[name]
			end
		end
	end
end

local function _PropagateInstanceMethod(aClass, name, func)
	func = (name == "__index") and _CreateIndexWrapper(aClass, func) or func

	aClass.__InstanceDictionary[name] = func

	for subclass in pairs(aClass.Subclasses) do
		if rawget(subclass.__DeclaredMethods, name) == nil then
			_PropagateInstanceMethod(subclass, name, func)
		end
	end
end

local function _DeclareInstanceMethod(aClass, name, func)
	aClass.__DeclaredMethods[name] = func

	if not func and aClass.Super then
		func = aClass.Super.__InstanceDictionary[name]
	end

	_PropagateInstanceMethod(aClass, name, func)
end

local function _ToString(self)
	return "class " .. self.Name
end

local function _Call(self, ...)
	return self:New(...)
end

local function _CreateClass(name, super)
	local dict = {}

	dict.__index = dict

	local aClass = {
		Name = name,
		Super = super,
		Static = {},
		Subclasses = setmetatable({}, {__mode = "k"}),
		__InstanceDictionary = dict,
		__DeclaredMethods = {},
	}

	if super then
		setmetatable(aClass.Static, {
			__index = function(_, k)
				local res = rawget(dict, k)

				if res == nil then
					return super.Static[k]
				end

				return res
			end
		})
	else
		setmetatable(aClass.Static, {
			__index = function(_, k)
				return rawget(dict, k)
			end
		})
	end

	setmetatable(aClass, {
		__index = aClass.Static,
		__tostring = _ToString,
		__call = _Call,
		__newindex = _DeclareInstanceMethod
	})

	for instance in pairs(TankLib.Class.Instances) do
		if instance.Class.Name == name then
			instance.Class = aClass

			setmetatable(instance, aClass.__InstanceDictionary)
		end
	end

	class.Classes[name] = aClass

	return aClass
end

local function _Mixin(aClass, mixin)
	for name, method in pairs(mixin) do
		if name != "Included" and name != "Static" then
			aClass[name] = method
		end
	end

	if mixin.Static then
		for name, method in pairs(mixin.Static) do
			aClass.Static[name] = method
		end
	end

	if isfunction(mixin.Included) then
		mixin:Included(aClass)
	end

	return aClass
end

local _DefaultMixin = {
	__tostring = function(self) return "instance of " .. tostring(self.Class) end,

	Initialize = function(self, ...) end,

	IsInstanceOf = function(self, aClass)
		return istable(aClass)
			and istable(self)
			and (self.Class == aClass or istable(self.Class)
			and isfunction(self.Class.IsSubclassOf)
			and self.Class:IsSubclassOf(aClass))
	end,

	Static = {
		Allocate = function(self)
			return setmetatable({Class = self}, self.__InstanceDictionary)
		end,
		New = function(self, ...)
			local instance = self:Allocate()

			instance:Initialize(...)

			class.Instances[instance] = true

			return instance
		end,
		Subclass = function(self, name)
			local subclass = _CreateClass(name, self)

			for method, func in pairs(self.__InstanceDictionary) do
				_PropagateInstanceMethod(subclass, method, func)
			end

			subclass.Initialize = function(instance, ...)
				return self.Initialize(instance, ...)
			end

			self.Subclasses[subclass] = true
			self:Subclassed(subclass)

			return subclass
		end,
		Subclassed = function(self, other) end,
		IsSubclassOf = function(self, other)
			return istable(other) and istable(self) and (self.Super == other or self.Super:IsSubclassOf(other))
		end,
		Include = function(self, ...)
			for _, mixin in ipairs({...}) do
				_Mixin(self, mixin)
			end

			return self
		end
	}
}

function class:New(name, super)
	return super and super:Subclass(name) or _Mixin(_CreateClass(name), _DefaultMixin)
end

function class:GetByName(name)
	return self.Classes[name]
end

function class:GetNetworked(id)
	return self.NetworkTable[id]
end

TankLib.Class = class
TankLib:LoadFolder("mixins")
TankLib:LoadFolder("classes")