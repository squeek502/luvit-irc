require("tap")(function(test)
	local IRC = require "../"
	local c = IRC:new()

	test("isctcp", function()
		assert(c:_isctcp("\001test\001"))
	end)
end)