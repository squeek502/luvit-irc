require("luvit-test/helper")

local c = require "luvit-irc":new()
local Modes = require "luvit-irc/lib/modes"

c:_handlemsg(":warden.esper.net 005 lubot3 SAFELIST ELIST=CTU CHANTYPES=# EXCEPTS INVEX CHANMODES=eIbq,k,flj,CFLPQTcgimnprstz CHANLIMIT=#:50 PREFIX=(ov)@+ MAXLIST=bqeI:100 MODES=4 NETWORK=EsperNet KNOCK :are supported by this server")

assert_equal(26, #Modes.flags)
assert_equal("o", Modes.getmodebyprefix("@").flag)
assert_equal("@", Modes.getprefixbyflag("o"))

c:_addchannel("#test")
local channel = c:getchannel("#test")

c:_handlemsg(":portlane.esper.net 353 lubot3 = #test :lubot3 @test")

assert(channel:getuser("test") ~= nil)
assert_equal(channel, channel:getuser("test").parent)

Modes.clear()
assert_equal(0, #Modes.flags, Modes.flags)
assert_equal(nil, Modes["e"])