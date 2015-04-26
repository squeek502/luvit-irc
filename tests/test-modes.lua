require("tap")(function(test)
	local IRC = require "../"
	local Modes = IRC.Modes

	local c = IRC:new()

	test("server settings", function()
		c:_handlemsg(":warden.esper.net 005 lubot3 SAFELIST ELIST=CTU CHANTYPES=# EXCEPTS INVEX CHANMODES=eIbq,k,flj,CFLPQTcgimnprstz CHANLIMIT=#:50 PREFIX=(ov)@+ MAXLIST=bqeI:100 MODES=4 NETWORK=EsperNet KNOCK :are supported by this server")

		assert(26 == #Modes.flags)
		assert("o" == Modes.getmodebyprefix("@").flag)
		assert("@" == Modes.getprefixbyflag("o"))
	end)

	test("channel userlist", function()
		c:_addchannel("#test")
		local channel = c:getchannel("#test")

		c:_handlemsg(":portlane.esper.net 353 lubot3 = #test :lubot3 @test")

		assert(channel:getuser("test") ~= nil)
		assert(channel == channel:getuser("test").parent)
	end)

	test("clear", function()
		Modes.clear()
		assert(0 == #Modes.flags, Modes.flags)
		assert(nil == Modes["e"])
	end)
end)
