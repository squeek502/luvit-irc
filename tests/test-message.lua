require("luvit-test/helper")

local Message = require "irc/message"
local string = require "string"

local msg

-- fromstring and tostring tests
msg = Message.fromstring("COMMAND")
assert_equal("COMMAND", msg.command)
assert_equal(0, #msg.args)
assert_equal("COMMAND", tostring(msg))

msg = Message.fromstring("COMMAND arg")
assert_equal("COMMAND", msg.command)
assert_equal(1, #msg.args)
assert_equal("arg", msg.args[1])
assert_equal("COMMAND arg", tostring(msg))

msg = Message.fromstring("COMMAND :arg with spaces")
assert_equal("COMMAND", msg.command)
assert_equal(1, #msg.args)
assert_equal("arg with spaces", msg.args[1])
assert_equal("COMMAND :arg with spaces", tostring(msg))

msg = Message.fromstring("COMMAND :argwithoutspaces")
assert_equal("COMMAND argwithoutspaces", tostring(msg))

msg = Message.fromstring(":irc.server COMMAND")
assert_equal("irc.server", msg.server)
assert_equal("COMMAND", msg.command)
assert_equal(0, #msg.args)
assert_deep_equal({}, msg.args)
assert_equal(":irc.server COMMAND", tostring(msg))

msg = Message.fromstring(":irc.server COMMAND arg1 :arg with spaces")
assert_equal("irc.server", msg.server)
assert_equal("COMMAND", msg.command)
assert_equal(2, #msg.args)
assert_equal("arg1", msg.args[1])
assert_equal("arg with spaces", msg.args[2])
assert_equal(":irc.server COMMAND arg1 :arg with spaces", tostring(msg))

msg = Message.fromstring(":irc.server COMMAND arg1 arg2 :arg with spaces")
assert_equal("irc.server", msg.server)
assert_equal("COMMAND", msg.command)
assert_equal(3, #msg.args)
assert_equal("arg1", msg.args[1])
assert_equal("arg2", msg.args[2])
assert_equal("arg with spaces", msg.args[3])
assert_equal(":irc.server COMMAND arg1 arg2 :arg with spaces", tostring(msg))

msg = Message.fromstring(":nick!user@host COMMAND")
assert_equal(nil, msg.server)
assert_equal("nick", msg.nick)
assert_equal("user", msg.user)
assert_equal("host", msg.host)
assert_equal("COMMAND", msg.command)
assert_equal(":nick!user@host COMMAND", tostring(msg))

msg = Message.fromstring(":nick@host COMMAND")
assert_equal(nil, msg.server)
assert_equal("nick", msg.nick)
assert_equal(nil, msg.user)
assert_equal("host", msg.host)
assert_equal("COMMAND", msg.command)
assert_equal(":nick@host COMMAND", tostring(msg))

msg = Message.fromstring(":nick COMMAND")
assert_equal(nil, msg.server)
assert_equal("nick", msg.nick)
assert_equal(nil, msg.user)
assert_equal(nil, msg.host)
assert_equal("COMMAND", msg.command)
assert_equal(":nick COMMAND", tostring(msg))

-- constructor tests
msg = Message:new("COMMAND")
assert_equal(0, #msg.args)

msg = Message:new("COMMAND", "test")
assert_equal(1, #msg.args)
assert_equal("test", msg.args[1])

local varnil = nil
msg = Message:new("COMMAND", "test", varnil)
assert_equal(1, #msg.args)
assert_equal("test", msg.args[1])

msg = Message:new("COMMAND", "test", "arg2")
assert_equal(2, #msg.args)
assert_equal("test", msg.args[1])
assert_equal("arg2", msg.args[2])
