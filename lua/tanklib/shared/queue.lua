local class = TankLib.Class("TankLib.Queue")

function class:Initialize(...)
	self.First = 0
	self.Last = -1
	self.Items = {}

	for _, v in ipairs({...}) do
		self:Push(v)
	end
end

function class:Push(item)
	local index = self.Last + 1

	self.Last = index
	self.Items[index] = item
end

function class:Pop()
	local index = self.First

	if index > self.Last then
		return
	end

	local item = self.Items[index]

	self.Items[index] = nil
	self.First = index + 1

	return item
end

function class:Count()
	return self.Last - self.First + 1
end

TankLib.Queue = class