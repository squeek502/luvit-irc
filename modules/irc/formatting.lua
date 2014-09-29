local string = require "string"
local table = require "table"
local util = require "./util"
local utils = require "utils"

local Formatting = {}

Formatting.Colors = {
	START = string.char(3),
	WHITE = '00',
	BLACK = '01',
	DARK_BLUE = '02',
	DARK_GREEN = '03',
	LIGHT_RED = '04',
	DARK_RED = '05',
	MAGENTA = '06',
	ORANGE = '07',
	YELLOW = '08',
	LIGHT_GREEN = '09',
	CYAN = '10',
	LIGHT_CYAN = '11',
	LIGHT_BLUE = '12',
	LIGHT_MAGENTA = '13',
	GRAY = '14',
	LIGHT_GRAY = '15',
}

Formatting.Styles = {
	BOLD = string.char(2),
	UNDERLINE = string.char(31),
	ITALIC = string.char(29),
	REVERSE = string.char(18),
	REVERSE_DEPRECATED = string.char(22),
	RESET = string.char(15),
}
local allstyles = ""
for name,style in pairs(Formatting.Styles) do
	allstyles = allstyles..style
end

Formatting.stripstyles = function(str)
	return str:gsub("["..allstyles.."]", "")
end

Formatting.stripbackgrounds = function(str)
	return str:gsub("("..Formatting.Colors.START.."%d%d?),%d%d?", "%1")
end

Formatting.stripcolors = function(str)
	str = Formatting.stripbackgrounds(str)
	return str:gsub(Formatting.Colors.START.."%d?%d?", "")
end

Formatting.strip = function(str)
	return Formatting.stripstyles(Formatting.stripcolors(str))
end

Formatting.colorize = function(text, color, background)
	return string.format("%s%s%s", 
		Formatting.Colors.START..color..(background and ","..background or ""),
		text,
		Formatting.Styles.RESET)
end

Formatting.stylize = function(text, style)
	return string.format("%s%s%s", style, text, style)
end

Formatting.Conversion =
{
	[Formatting.Styles.RESET] = utils.color(),
	[Formatting.Colors.WHITE] = utils.color("Bwhite"),
	[Formatting.Colors.BLACK] = utils.color("black"),
	[Formatting.Colors.DARK_BLUE] = utils.color("blue"),
	[Formatting.Colors.DARK_GREEN] = utils.color("green"),
	[Formatting.Colors.LIGHT_RED] = utils.color("Bred"),
	[Formatting.Colors.DARK_RED] = utils.color("red"),
	[Formatting.Colors.MAGENTA] = utils.color("magenta"),
	[Formatting.Colors.ORANGE] = utils.color("yellow"),
	[Formatting.Colors.YELLOW] = utils.color("Byellow"),
	[Formatting.Colors.LIGHT_GREEN] = utils.color("Bgreen"),
	[Formatting.Colors.CYAN] = utils.color("cyan"),
	[Formatting.Colors.LIGHT_CYAN] = utils.color("Bcyan"),
	[Formatting.Colors.LIGHT_BLUE] = utils.color("Bblue"),
	[Formatting.Colors.LIGHT_MAGENTA] = utils.color("Bmagenta"),
	[Formatting.Colors.GRAY] = utils.color("Bblack"),
	[Formatting.Colors.LIGHT_GRAY] = utils.color("white"),
}

Formatting.convert = function(text)
	text = text:gsub(Formatting.Styles.RESET, Formatting.Conversion[Formatting.Styles.RESET])
	text = Formatting.stripstyles(text)
	text = Formatting.stripbackgrounds(text)
	local replacements = {}
	for colorstring in string.gmatch(text, Formatting.Colors.START.."%d?%d?") do
		local color_code = colorstring:sub(2)
		if color_code:len() == 0 then
			color_code = Formatting.Styles.RESET
		elseif color_code:len() == 1 then
			color_code = '0'..color_code
		end
		local conversion = Formatting.Conversion[color_code] or utils.color()
		table.insert(replacements, {needle=colorstring, replacement=conversion})
	end
	for _,replacement in ipairs(replacements) do
		text = util.string.findandreplace(text, replacement.needle, replacement.replacement)
	end
	return text..utils.color()
end

Formatting.print = function(text)
	print(Formatting.convert(text))
end

return Formatting