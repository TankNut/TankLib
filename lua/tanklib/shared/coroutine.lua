function coroutine.Call(func, ...)
	local cr = coroutine.create(func)

	coroutine.Run(cr, ...)
end

function coroutine.Run(cr, ...)
	local ok, err = coroutine.resume(cr, ...)

	if not ok then
		local msg = string.format("\n\n--- ERROR IN COROUTINE ---\n\n%s\n\n--- END OF COROUTINE ERROR ---\n", debug.traceback(cr, "[ERROR] " .. err))

		error(msg)
	end
end

function coroutine.Valid()
	return assert(coroutine.running(), "Code has to be ran from inside a coroutine")
end

function coroutine.WaitUntil(interval, func, timeout)
	local cr = coroutine.Valid()
	local time = 0

	local function check()
		local ok, args = func()

		if ok then
			coroutine.Run(cr, true, unpack(args))

			return
		end

		if time > timeout then
			coroutine.Run(cr, false, unpack(args))

			return
		end

		time = time + interval

		timer.Simple(interval, check)
	end

	return coroutine.yield()
end