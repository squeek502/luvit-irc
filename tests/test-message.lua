require("tap")(function(test)
	local IRC = require "../"
	local Message = IRC.Message
	local msg

	test("fromstring and tostring", function()
		-- fromstring and tostring tests
		msg = Message.fromstring("COMMAND")
		assert("COMMAND" == msg.command)
		assert(0 == #msg.args)
		assert("COMMAND" == tostring(msg))

		msg = Message.fromstring("COMMAND arg")
		assert("COMMAND" == msg.command)
		assert(1 == #msg.args)
		assert("arg" == msg.args[1])
		assert("COMMAND arg" == tostring(msg))

		msg = Message.fromstring("COMMAND :arg with spaces")
		assert("COMMAND" == msg.command)
		assert(1 == #msg.args)
		assert("arg with spaces" == msg.args[1])
		assert("COMMAND :arg with spaces" == tostring(msg))

		msg = Message.fromstring("COMMAND :argwithoutspaces")
		assert("COMMAND argwithoutspaces" == tostring(msg))

		msg = Message.fromstring(":irc.server COMMAND")
		assert("irc.server" == msg.server)
		assert("COMMAND" == msg.command)
		assert(0 == #msg.args)
		assert(":irc.server COMMAND" == tostring(msg))

		msg = Message.fromstring(":irc.server COMMAND arg1 :arg with spaces")
		assert("irc.server" == msg.server)
		assert("COMMAND" == msg.command)
		assert(2 == #msg.args)
		assert("arg1" == msg.args[1])
		assert("arg with spaces" == msg.args[2])
		assert(":irc.server COMMAND arg1 :arg with spaces" == tostring(msg))

		msg = Message.fromstring(":irc.server COMMAND arg1 arg2 :arg with spaces")
		assert("irc.server" == msg.server)
		assert("COMMAND" == msg.command)
		assert(3 == #msg.args)
		assert("arg1" == msg.args[1])
		assert("arg2" == msg.args[2])
		assert("arg with spaces" == msg.args[3])
		assert(":irc.server COMMAND arg1 arg2 :arg with spaces" == tostring(msg))

		msg = Message.fromstring(":nick!user@host COMMAND")
		assert(nil == msg.server)
		assert("nick" == msg.nick)
		assert("user" == msg.user)
		assert("host" == msg.host)
		assert("COMMAND" == msg.command)
		assert(":nick!user@host COMMAND" == tostring(msg))

		msg = Message.fromstring(":nick@host COMMAND")
		assert(nil == msg.server)
		assert("nick" == msg.nick)
		assert(nil == msg.user)
		assert("host" == msg.host)
		assert("COMMAND" == msg.command)
		assert(":nick@host COMMAND" == tostring(msg))

		msg = Message.fromstring(":nick COMMAND")
		assert(nil == msg.server)
		assert("nick" == msg.nick)
		assert(nil == msg.user)
		assert(nil == msg.host)
		assert("COMMAND" == msg.command)
		assert(":nick COMMAND" == tostring(msg))
	end)

	test("constructors", function()
		msg = Message:new("COMMAND")
		assert(0 == #msg.args)

		msg = Message:new("COMMAND", "test")
		assert(1 == #msg.args)
		assert("test" == msg.args[1])

		local varnil = nil
		msg = Message:new("COMMAND", "test", varnil)
		assert(1 == #msg.args)
		assert("test" == msg.args[1])

		msg = Message:new("COMMAND", "test", "arg2")
		assert(2 == #msg.args)
		assert("test" == msg.args[1])
		assert("arg2" == msg.args[2])
	end)
end)
