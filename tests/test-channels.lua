require("luvit-test/helper")

local c = require "luvit-irc":new()
local Channel = require "luvit-irc/lib/channel"
local testchannel = Channel:new(c, "#testchannel")
local samechannel = Channel:new(c, "#testchannel")
local otherchannel = Channel:new(c, "#otherchannel")

assert(not testchannel:is(otherchannel))
assert(testchannel:is(samechannel))
assert(testchannel:is("#testchannel"))

testchannel:adduser("test")

assert(testchannel:getuser("test") ~= nil)
assert_equal(testchannel, testchannel:getuser("test").parent)