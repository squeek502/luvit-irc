require("luvit-test/helper")

local Formatting = require "luvit-irc/lib/formatting"
local util = require "luvit-irc/lib/util"
local utils = require "utils"

-- stripstyles
assert_equal("test", Formatting.stripstyles(Formatting.stylize("test", Formatting.Styles.ITALIC)))
assert_equal("test", Formatting.stripstyles(Formatting.stylize("test", Formatting.Styles.BOLD)))
assert_equal("test", Formatting.stripstyles(Formatting.stylize("test", Formatting.Styles.RESET)))
assert_equal("test", Formatting.stripstyles(Formatting.stylize("test", Formatting.Styles.UNDERLINE)))
assert_equal("test", Formatting.stripstyles(Formatting.stylize("test", Formatting.Styles.REVERSE)))
assert_equal("test", Formatting.stripstyles(Formatting.stylize("test", Formatting.Styles.REVERSE_DEPRECATED)))
assert_equal(Formatting.Colors.START..Formatting.Colors.DARK_RED.."test", Formatting.stripstyles(Formatting.colorize("test", Formatting.Colors.DARK_RED)))

-- stripbackgrounds
assert_equal(Formatting.colorize("test", Formatting.Colors.WHITE), Formatting.stripbackgrounds(Formatting.colorize("test", Formatting.Colors.WHITE, Formatting.Colors.BLACK)))

-- stripcolors
assert_equal("test" .. Formatting.Styles.RESET, Formatting.stripcolors(Formatting.colorize("test", Formatting.Colors.WHITE, Formatting.Colors.BLACK)))

local ircformatteststring = 
	Formatting.colorize("@", Formatting.Colors.WHITE, Formatting.Colors.BLACK) ..
	Formatting.colorize("@", Formatting.Colors.BLACK, Formatting.Colors.BLACK) ..
	Formatting.colorize("@", Formatting.Colors.DARK_BLUE, Formatting.Colors.BLACK) ..
	Formatting.colorize("@", Formatting.Colors.DARK_GREEN, Formatting.Colors.BLACK) ..
	Formatting.colorize("@", Formatting.Colors.LIGHT_RED) ..
	Formatting.colorize("@", Formatting.Colors.DARK_RED) ..
	Formatting.colorize("@", Formatting.Colors.MAGENTA) ..
	Formatting.colorize("@", Formatting.Colors.ORANGE) ..
	Formatting.colorize("@", Formatting.Colors.YELLOW) ..
	Formatting.colorize("@", Formatting.Colors.LIGHT_GREEN) ..
	Formatting.colorize("@", Formatting.Colors.CYAN) ..
	Formatting.colorize("@", Formatting.Colors.LIGHT_CYAN) ..
	Formatting.colorize("@", Formatting.Colors.LIGHT_BLUE) ..
	Formatting.colorize("@", Formatting.Colors.LIGHT_MAGENTA) ..
	Formatting.colorize("@", Formatting.Colors.GRAY) ..
	Formatting.colorize("@", Formatting.Colors.LIGHT_GRAY) ..
	Formatting.Styles.RESET .. "@" ..
	Formatting.stylize("@", Formatting.Styles.BOLD) ..
	Formatting.stylize("@", Formatting.Styles.UNDERLINE) ..
	Formatting.stylize("@", Formatting.Styles.ITALIC) ..
	Formatting.stylize("@", Formatting.Styles.REVERSE)

-- strip formatting
assert_equal("@@@@@@@@@@@@@@@@@@@@@", Formatting.strip(ircformatteststring))

local luvitformatteststring = 
	utils.colorize("Bwhite", "@") ..
	utils.colorize("black", "@") ..
	utils.colorize("blue", "@") ..
	utils.colorize("green", "@") ..
	utils.colorize("Bred", "@") ..
	utils.colorize("red", "@") ..
	utils.colorize("magenta", "@") ..
	utils.colorize("yellow", "@") ..
	utils.colorize("Byellow", "@") ..
	utils.colorize("Bgreen", "@") ..
	utils.colorize("cyan", "@") ..
	utils.colorize("Bcyan", "@") ..
	utils.colorize("Bblue", "@") ..
	utils.colorize("Bmagenta", "@") ..
	utils.colorize("Bblack", "@") ..
	utils.colorize("white", "@") ..
	utils.color() .. "@" ..
	"@" ..
	"@" ..
	"@" ..
	"@" .. utils.color()

local converted = Formatting.convert(ircformatteststring)

print(luvitformatteststring)
print(converted)

assert_equal(luvitformatteststring, converted)