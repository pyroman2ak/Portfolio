--[[
  Signal.lua
  Signal System by Madwork
  Source: https://github.com/MadStudioRoblox/Madwork-Zero
  Used under open-source license.
  Integrated and maintained by pyroman2ak for the Engine framework.
]]

local Signal = {}
Signal.__index = Signal

function Signal.new()
	local self = setmetatable({}, Signal)
	self._handlerListHead = false
	return self
end

function Signal:Connect(Handler)
	assert(type(Handler) == "function", "Handler must be a function.")

	local Connection = {
		_Handler = Handler,
		_Connected = true,
		_Signal = self,
	}

	if self._handlerListHead then
		Connection._Next = self._handlerListHead
		self._handlerListHead._Prev = Connection
	end
	self._handlerListHead = Connection

	function Connection:Disconnect()
		if not self._Connected then
			return
		end
		self._Connected = false
		if self._Signal._handlerListHead == self then
			self._Signal._handlerListHead = self._Next
		end

		if self._Prev then
			self._Prev._Next = self._Next
		end

		if self._Next then
			self._Next._Prev = self._Prev
		end
	end

	return Connection
end

function Signal:Fire(...)
	local Item = self._handlerListHead
	while Item do
		if Item._Connected then
			task.spawn(Item._Handler, ...)
		end
		Item = Item._Next
	end
end

function Signal:Wait()
	local Thread = coroutine.running()
	local Connection
	Connection = self:Connect(function(...: any)
		Connection:Disconnect()
		task.spawn(Thread, ...)
	end)
	return coroutine.yield()
end

return Signal
