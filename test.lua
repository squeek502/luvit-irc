local IRC = require ('luvit-irc')
local Formatting = require "luvit-irc/lib/formatting"
local string = require "string"

local server = "irc.esper.net"
local ssl = false
local nick = "lubot3"

local channel = ""

local c = IRC:new (server, nick, {ssl=ssl, auto_join={"#squeektest"}})
c:on ("connect", function (x)
	if not x then
		print ("Cannot connect")
		process.exit (1)
	end
	p ("Connected")
end)
c:on ("error", function (msg)
	p ("error", msg)
	process.exit (1)
end)
c:on ("notice", function (from, to, msg)
	from = from or c.server
	print(string.format("-%s:%s- %s", from, to, msg))
end)
c:on ("data", function (x)
	--print ("::: "..x)
end)
c:on ("join", function (channel, whojoined)
	if c:isme(whojoined) then
		print(string.format("Joined channel: %s", channel))
		channel:on("+mode", function(mode, setby, param)
			if setby == nil then return end
			print(string.format("[%s] %s sets mode: %s%s",
				channel,
				setby,
				"+"..mode.flag,
				(param and " "..param or "")
			))
		end)
		channel:on("-mode", function(mode, setby, param)
			if setby == nil then return end
			print(string.format("[%s] %s sets mode: %s%s",
				channel,
				setby,
				"-"..mode.flag,
				(param and " "..param or "")
			))
		end)
		channel:on("quit", function(who, reason)
			print(string.format("[%s] %s has quit", channel, who)..(reason and " ("..reason..")" or ""))
		end)
		channel:on("part", function(who, reason)
			print(string.format("[%s] %s has left the channel", channel, who)..(reason and " ("..reason..")" or ""))
		end)
		channel:on("kick", function(who, by, reason)
			print(string.format("[%s] %s has been kicked from the channel by %s", channel, who, by)..(reason and " ("..reason..")" or ""))
		end)
		channel:on("kill", function(who)
			print(string.format("[%s] %s has been forcibly terminated by the server", channel, who))
		end)
	else
		print(string.format("[%s] %s has joined the channel", channel, whojoined))
	end
end)
c:on ("names", function(channel)
	for nick,user in pairs(channel.users) do
		print(" "..tostring(user))
	end
end)
c:on ("part", function (channel, wholeft, reason)
	if c:isme(wholeft) then
		print(string.format("Left channel: %s", channel))
	end
end)
c:on ("quit", function (whoquit, reason)
	if c:isme(whoquit) then
		print(string.format("Quit: %s", reason))
	end
end)
c:on ("pm", function (from, msg)
	print ("<"..from.."> "..Formatting.convert(msg))
end)
c:on ("message", function (from, to, msg)
	print ("["..to.."] <"..from.."> "..Formatting.convert(msg))
end)
c:on ("disconnect", function (...)
	p (...)
end)

function irc_cmd (input)
	local lines = require('irc/util').string.split(input, "\r?\n")

	for _,line in ipairs(lines) do
		if line ~= "" then
			local args = require('irc/util').string.split(line, " ")
			if args[1] == "/quit" then
				c:disconnect ()
			elseif args[1] == "/connect" then
				c:connect ()
			elseif args[1] == "/join" then
				channel = args[2]
				c:join (channel)
			elseif args[1] == "/part" then
				c:part (#args > 1 and args[2] or channel)
			elseif args[1] == "/query" then
				local target = args[2]
				local text = require('irc/util').string.join(require('irc/util').table.slice(args, 3), " ")
				c:say (target, text)
			elseif args[1] == "/names" then
				c:names (channel)
			elseif line:sub (1, 1) == "!" then
				c:write (line:sub (2).."\n")
			else
				c:say (channel, line)
			end
		end
	end
end

p("connecting to "..server)
c:connect ()
process.stdin:readStart ()
process.stdin:on ("data", function (line)
	irc_cmd (line)
end)
