require("tap")(function(test)
	local IRC = require "../"
	local c = IRC:new()

	test("splitmsg", function()
		local splitmsg = c:_splitlines("line without CRNL")
		assert(0 == #splitmsg)
		assert("line without CRNL" == c.buffer)

		splitmsg = c:_splitlines("line with CRNL\r\n")
		assert(1 == #splitmsg)
		assert("" == c.buffer)

		splitmsg = c:_splitlines("line with CRNL\r\nand another")
		assert(1 == #splitmsg)
		assert("and another" == c.buffer)

		splitmsg = c:_splitlines("line with CRNL\r\nand another with CRNL\r\n")
		assert(2 == #splitmsg)
		assert("" == c.buffer)
	end)
end)

