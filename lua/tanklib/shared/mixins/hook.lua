local mixin = {}

function mixin:IsValid()
	return true
end

function mixin:Hook(event)
	hook.Add(event, self, self[event])
end

TankLib.Class.Mixins.Hook = mixin