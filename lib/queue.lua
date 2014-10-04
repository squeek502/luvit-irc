local Object = require "core".Object

local Queue = Object:extend()

function Queue:initialize(connection, transferlimit)
	self.connection = connection
	self.queue = {}
	self.transferred = 0
	self.sent = 0
	self.locked = false
	self.transferlimit = transferlimit or 1024
	self.sendlimit = 10
end

function Queue:push(msg)
	table.insert(self.queue, msg)
	self:process()
end

function Queue:pop()
	return table.remove(self.queue, 1)
end

function Queue:clear()
	self.queue = {}
	self:unlock()
end

function Queue:lock()
	self.locked = true
	self.connection:ping()
end

function Queue:unlock()
	self.locked = false
	self.transferred = 0
	self.sent = 0
	self:process()
end

function Queue:isready()
	return not self.locked and #self.queue > 0
end

function Queue:peek()
	return self.queue[1]
end

function Queue:peeksize()
	local peekmsg = self:peek()
	return peekmsg and peekmsg:size() or 0
end

function Queue:cansend()
	return self.transferred + self:peeksize() <= self.transferlimit and self.sent < self.sendlimit
end

function Queue:process()
	while self:isready() do
		if self:cansend() then
			local msg = self:pop()
			self.connection:_send(msg)
			self.transferred = self.transferred + msg:size()
			self.sent = self.sent + 1
		else
			self:lock()
		end
	end
end

return Queue