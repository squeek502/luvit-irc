function deep_equal(expected, actual, msg)
  if type(expected) == 'table' and type(actual) == 'table' then
    if #expected ~= #actual then return false end
    for k, v in pairs(expected) do
      if not deep_equal(v, actual[k]) then return false end
    end
    return true
  else
    return expected == actual
  end
end

require("tap")(function(test)
	local util = require "../lib/util"

	test("string.join", function()
		local joined = util.string.join({"one", "two", "three"})
		assert("string" == type(joined))
		assert("onetwothree" == joined)

		joined = util.string.join({})
		assert("" == joined)

		joined = util.string.join({"one", "two", "three"}, ", ")
		assert("one == two, three", joined)

		joined = util.string.join({"one"}, ", ")
		assert("one" == joined)
	end)

	test("table.slice", function()
		local unsliced = {"one", "two"}
		local sliced = util.table.slice(unsliced, 1, -1)
		assert(deep_equal({"one"}, sliced))

		local sliced = util.table.slice(unsliced, -1)
		assert(deep_equal({"two"}, sliced))
	end)

	test("string.findandreplace", function()
		assert("testtest" == util.string.findandreplace("testatest", "a", ""))
		assert("test11test" == util.string.findandreplace("test(%s)test", "(%s)", "11"))
	end)

	test("string.split", function()
		assert(deep_equal({"a","b","c"}, util.string.split("abc", "")))

		assert(deep_equal({"test"}, util.string.split("test", "[\r\n]+")))
		assert(deep_equal({"test", "test"}, util.string.split("test\ntest", "[\r\n]+")))
		assert(deep_equal({"test", "test"}, util.string.split("test\r\ntest", "[\r\n]+")))
		assert(deep_equal({"test", "test"}, util.string.split("test\n\n\ntest", "[\r\n]+")))

		local lines = util.string.split("test\r\ntest\r", "[\r\n]+")
		if lines[#lines] == "" then table.remove(lines) end
		assert(deep_equal({"test", "test"}, lines))
	end)
end)