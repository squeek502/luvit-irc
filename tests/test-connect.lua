require("luvit-test/helper")

local c = require "irc":new()

local dummymsg = "Dummy welcome message"
local dummyserver = "dummy.irc.net"
local dummynick = "dummynick"

c:on("connect", function(msg, host, nick)
	assert_equal(dummymsg, msg)
	assert_equal(dummyserver, host)
	assert_equal(dummynick, nick)
end)

c:_handlemsg(":"..dummyserver.." 001 "..dummynick.." :"..dummymsg)

assert(c.connected, "Recieving a welcome message marks the client as connected")