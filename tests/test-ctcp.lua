require("luvit-test/helper")

local c = require "luvit-irc":new()

assert(c:_isctcp("\001test\001"))