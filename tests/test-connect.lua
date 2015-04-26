require('tap')(function(test)
	local IRC = require "../"

	local c = IRC:new()
	-- necessary to stop the sendqueue's interval blocking the test from finishing
	c.sendqueue:disable()

	local dummymsg = "Dummy welcome message"
	local dummyserver = "dummy.irc.net"
	local dummynick = "dummynick"

	test("connect event handling", function(expect)
		c:on("connect", expect(function(msg, host, nick)
			assert(dummymsg == msg)
			assert(dummyserver == host)
			assert(dummynick == nick)
		end))

		c:_handlemsg(":"..dummyserver.." 001 "..dummynick.." :"..dummymsg)

		assert(c.connected, "Recieving a welcome message marks the client as connected")
	end)
end)