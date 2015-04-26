require("tap")(function(test)
	local IRC = require "../"
	local Formatting = IRC.Formatting

	test("stripping", function()
		-- stripstyles
		assert("test" == Formatting.stripstyles(Formatting.stylize("test", Formatting.Styles.ITALIC)))
		assert("test" == Formatting.stripstyles(Formatting.stylize("test", Formatting.Styles.BOLD)))
		assert("test" == Formatting.stripstyles(Formatting.stylize("test", Formatting.Styles.RESET)))
		assert("test" == Formatting.stripstyles(Formatting.stylize("test", Formatting.Styles.UNDERLINE)))
		assert("test" == Formatting.stripstyles(Formatting.stylize("test", Formatting.Styles.REVERSE)))
		assert("test" == Formatting.stripstyles(Formatting.stylize("test", Formatting.Styles.REVERSE_DEPRECATED)))
		assert(Formatting.Colors.START..Formatting.Colors.DARK_RED.."test" == Formatting.stripstyles(Formatting.colorize("test", Formatting.Colors.DARK_RED)))

		-- stripbackgrounds
		assert(Formatting.colorize("test", Formatting.Colors.WHITE) == Formatting.stripbackgrounds(Formatting.colorize("test", Formatting.Colors.WHITE, Formatting.Colors.BLACK)))

		-- stripcolors
		assert("test" .. Formatting.Styles.RESET == Formatting.stripcolors(Formatting.colorize("test", Formatting.Colors.WHITE, Formatting.Colors.BLACK)))
	end)

	test("conversion", function()
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
		assert("@@@@@@@@@@@@@@@@@@@@@" == Formatting.strip(ircformatteststring))

		local converted = Formatting.convert(ircformatteststring)

		print(converted)

		assert(converted ~= ircformatteststring)
	end)
end)