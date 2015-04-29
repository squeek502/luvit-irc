return require('luvit')(function(...)
	-- make args luvit-friendly by shifting it to be 1-indexed
	_G.args = {args[0], ...}

	require "."
end, ...)