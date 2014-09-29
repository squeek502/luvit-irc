require("luvit-test/helper")

local c = require "irc":new()

local splitmsg = c:_splitlines("line without CRNL")
assert_equal(0, #splitmsg)
assert_equal("line without CRNL", c.buffer)

splitmsg = c:_splitlines("line with CRNL\r\n")
assert_equal(1, #splitmsg)
assert_equal("", c.buffer)

splitmsg = c:_splitlines("line with CRNL\r\nand another")
assert_equal(1, #splitmsg)
assert_equal("and another", c.buffer)

splitmsg = c:_splitlines("line with CRNL\r\nand another with CRNL\r\n")
assert_equal(2, #splitmsg)
assert_equal("", c.buffer)