require("luvit-test/helper")

local c = require "irc":new()
local channel = require "irc/channel":new(c, "#testchannel")
local samechannel = require "irc/channel":new(c, "#testchannel")
local otherchannel = require "irc/channel":new(c, "#otherchannel")

assert(not channel:is(otherchannel))
assert(channel:is(samechannel))
assert(channel:is("#testchannel"))

channel:adduser("test")

assert(channel:getuser("test") ~= nil)
assert_equal(channel, channel:getuser("test").parent)