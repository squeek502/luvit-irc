require('tap')(function(test)
	local IRC = require "../"

	local c = IRC:new()
	local testchannel = IRC.Channel:new(c, "#testchannel")
	local samechannel = IRC.Channel:new(c, "#testchannel")
	local otherchannel = IRC.Channel:new(c, "#otherchannel")

	test("channel equivalence", function()
		assert(not testchannel:is(otherchannel))
		assert(testchannel:is(samechannel))
		assert(testchannel:is("#testchannel"))
	end)

	test("user addition", function(expect)
		testchannel:adduser("test")

		assert(testchannel:getuser("test") ~= nil)
		assert(testchannel == testchannel:getuser("test").parent)
	end)

	test("user join", function(expect)
		c:emit("join", samechannel, "testnick")
		assert(testchannel:getuser("testnick") ~= nil)
	end)
end)