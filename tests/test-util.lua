require("luvit-test/helper")

local table = require "table"
local util = require "luvit-irc/lib/util"

local joined = util.string.join({"one", "two", "three"})
assert_equal("string", type(joined))
assert_equal("onetwothree", joined)

joined = util.string.join({})
assert_equal("", joined)

joined = util.string.join({"one", "two", "three"}, ", ")
assert_equal("one, two, three", joined)

joined = util.string.join({"one"}, ", ")
assert_equal("one", joined)

local unsliced = {"one", "two"}
local sliced = util.table.slice(unsliced, 1, -1)
assert_deep_equal({"one"}, sliced)

local sliced = util.table.slice(unsliced, -1)
assert_deep_equal({"two"}, sliced)

assert_equal("testtest", util.string.findandreplace("testatest", "a", ""))
assert_equal("test11test", util.string.findandreplace("test(%s)test", "(%s)", "11"))

assert_deep_equal({"a","b","c"}, util.string.split("abc", ""))

assert_deep_equal({"test"}, util.string.split("test", "[\r\n]+"))
assert_deep_equal({"test", "test"}, util.string.split("test\ntest", "[\r\n]+"))
assert_deep_equal({"test", "test"}, util.string.split("test\r\ntest", "[\r\n]+"))
assert_deep_equal({"test", "test"}, util.string.split("test\n\n\ntest", "[\r\n]+"))

local lines = util.string.split("test\r\ntest\r", "[\r\n]+")
if lines[#lines] == "" then table.remove(lines) end
assert_deep_equal({"test", "test"}, lines)