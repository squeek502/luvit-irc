-- author -- pancake@nopcode.org --
-- TODO: check SSL certificate

local instanceof = require('core').instanceof
local Emitter = require('core').Emitter
local dns = require('dns')
local TCP = require('uv').Tcp
local table = require('table')
local TLS = require('tls', false)
local string = require('string')
local util = require('./lib/util')
local Message = require('./lib/message')
local Channel = require('./lib/channel')
local Modes = require('./lib/modes')
local RPL = require('./lib/replies')
local ERR = require('./lib/errors')

local IRC = Emitter:extend()

function IRC:initialize(server, nick, options)
	self.server = server
	self.nick = nick
	self.options = options or {}
	util.table.fallback(self.options, {
		port = 6667,
		ssl = false,
		real_name = self.nick,
		username = self.nick,
		password = nil,
		invisible = false,
		max_retries = 99,
		retry_delay = 2000,
		auto_connect = false,
		auto_retry = true,
		auto_join = {},
		auto_rejoin = true,
	})
	self.sock = nil
	self.buffer = ""
	self.connected = false
	self.channels = {}
	self.retrycount = 0
	self.intentionaldisconnect = false

	if self.options.auto_connect then
		self:connect()
	end

	self:on("kick", function(channel, kicked, kickedby, reason)
		if self:isme(kicked) and self.options.auto_rejoin then
			self:join(channel)
		end
	end)
	self:on("connect", function(motd)
		for channel_or_i,channel_or_key in pairs(self.options.auto_join) do
			if type(channel_or_i) == "string" then
				self:join(channel_or_i, channel_or_key)
			else
				self:join(channel_or_key)
			end
		end
	end)
end

function IRC:connect(num_retries)
	if self.connected then
		self:_disconnected("Initiating new connection")
	end

	if num_retries then
		p ("Connect retry #"..num_retries.." to "..self.server)
	end

	dns.resolve4(self.server, function (err, addresses)
		server = addresses[1]
		if self.options.ssl then
			if not TLS then
				error ("luvit cannot require ('tls')")
			end
			TLS.connect (self.options.port, server, {}, function (err, client)
				self.sock = client
				self:_handlesock(client)
				self:_connect(self.nick, server)
			end)
		else
			local sock = TCP:new ()
			self.sock = sock
			sock:connect(server, self.options.port)
			self:_handlesock(sock)
			sock:on("connect", function ()
				sock:readStart()
				self:_connect(self.nick, server)
			end)
		end
	end)
end

function IRC:say(target, text)
	if target == "#" then
		for channelid,channel in pairs(self.channels) do
			self:say(channel.name, text)
		end
		return
	end
	local lines = util.string.split(text, "[\r\n]+")
	if lines[#lines] == "" then table.remove(lines) end
	for _,line in ipairs(lines) do
		self:send(Message:new("PRIVMSG", target, line))
	end
end

function IRC:notice(target, text)
	self:send(Message:new("NOTICE", target, text))
end

function IRC:action(target, text)
	self:say(target, self:_toctcp("ACTION", text))
end

function IRC:join(channels, keys)
	channels = type(channels) == "table" and util.string.join(channels, ",") or channels
	keys = type(keys) == "table" and util.string.join(keys, ",") or keys
	self:send(Message:new("JOIN", channels, keys))
end

function IRC:part(channels, message)
	channels = type(channels) == "table" and util.string.join(channels, ",") or channels
	self:send(Message:new("PART", channels, message))
end

function IRC:disconnect(reason)
	self.intentionaldisconnect = true
	if self.connected then
		self:send(Message:new("QUIT", reason))
		self:close()
	end
end

function IRC:names(channels)
	channels = type(channels) == "table" and util.string.join(channels, ",") or channels
	self:send(Message:new("NAMES", channels))
end

function IRC:send(msg, callback)
	self:write(tostring(msg).."\r\n", callback)
end

function IRC:write(msg, callback)
	self.sock:write(msg, callback)
end

function IRC:close()
	if not self.sock then return end
	if self.sock.socket then
		self.sock.socket:close() -- SSL
	else
		self.sock:close() -- TCP
	end
end

function IRC:getchannel(channelname)
	local identifier = Channel.identifier(channelname)
	return self.channels[identifier]
end

function IRC:isme(nick)
	return self.nick == nick
end

function IRC:_connect(nick, server)
	self.intentionaldisconnect = false
	if self.options.password ~= nil then
		self:send(Message:new("PASS", self.options.password))
	end
	self:send(Message:new("NICK", nick))
	local username = self.options.username or nick
	local modeflag = self.options.invisible and 8 or 0
	local unused_filler = "*"
	local real_name = self.options.real_name
	self:send(Message:new("USER", username, modeflag, unused_filler, real_name))
	self:emit("connecting", nick, server, username, real_name)
end

function IRC:_connected(msg, server)
	assert(not self.connected)
	self.connected = true
	self:emit("connect", msg, server, self.nick)
end

function IRC:_disconnected(msg)
	self.connected = false
	self.channels = {}
	self:emit("disconnect", msg, self.server, self.nick, self.options)

	if not self.intentionaldisconnect and self.auto_retry then
		self:connect(1)
	end
end

function IRC:_toctcp(type, text)
	return "\001"..type.." "..text.."\001"
end

function IRC:_isctcp(text)
	return text:len() > 2 and text:sub(1,1) == "\001" and text:find("\001", 2, true)
end

function IRC:_nickchanged(oldnick, newnick)
	if oldnick == newnick then return end
	if self:isme(oldnick) then
		self.nick = newnick
	end
	self:emit("nick", oldnick, newnick)
end

function IRC:_addchannel(channelname)
	assert(self:getchannel(channelname) == nil)
	local identifier = Channel.identifier(channelname)
	self.channels[identifier] = Channel:new(self, channelname)
end

function IRC:_removechannel(channelname)
	assert(self:getchannel(channelname) ~= nil)
	local identifier = Channel.identifier(channelname)
	self.channels[identifier] = nil
end

function IRC:_handlesock(sock)
	sock:on("data", function (data)
		local lines = self:_splitlines(data)
		for i = 1, #lines do
			local line = lines[i]
			local msg = self:_parsemsg(line)
			self:_handlemsg(msg)
			self:emit("data", line)
		end
	end)
	sock:on("error", function (err)
		self:_disconnected(err)
	end)
	sock:on("close", function (...)
		self:_disconnected("Socket closed")
	end)
	sock:on("end", function (...)
		self:_disconnected("Socket ended")
	end)
end

function IRC:_splitlines(rawlines)
	assert(type(rawlines) == "string")
	self.buffer = self.buffer..rawlines
	local lines = util.string.split(self.buffer, "\r\n")
	self.buffer = table.remove(lines)
	return lines
end

function IRC:_parsemsg(line)
	assert(type(line) == "string")
	return Message:fromstring(line)
end

function IRC:_handlemsg(msg)
	if type(msg) == "string" then
		msg = self:_parsemsg(msg)
	end
	assert(instanceof(msg, Message), type(msg))

	if msg.command == "PING" then
		self:send(Message:new("PONG", unpack(msg.args)))
		self:emit("ping", unpack(msg.args))
	elseif msg.command == "PRIVMSG" then
		local from = msg.nick
		local to = msg.args[1]
		local text = #msg.args >= 2 and msg.args[2] or ""
		if not self:_isctcp(text) then
			self:emit("message", from, to, text)
			if to == self.nick then
				self:emit("pm", from, text)
			end
		else
			-- TODO: handle ctcp
		end
	elseif msg.command == "JOIN" then
		local whojoined = msg.nick
		local channelname = msg.args[1]
		if self:isme(whojoined) then
			self:_addchannel(channelname)
			self:emit("ijoin", self:getchannel(channelname))
		end
		local channel = self:getchannel(channelname)
		self:emit("join", channel, whojoined)
	elseif msg.command == "PART" then
		local wholeft = msg.nick
		local channelname = msg.args[1]
		local reason = #msg.args >= 2 and msg.args[2] or nil
		local channel = self:getchannel(channelname)
		if self:isme(wholeft) then
			self:_removechannel(channelname)
			self:emit("ipart", channel, reason)
		end
		self:emit("part", channel, wholeft, reason)
	elseif msg.command == "NICK" then
		local oldnick = msg.nick
		local newnick = msg.args[1]
		self:_nickchanged(oldnick, newnick)
	elseif msg.command == "MODE" then
		local setby = msg.nick
		local channelname = msg.args[1]
		local modes = msg.args[2]
		local params = util.table.slice(msg.args, 3)
		local channel = self:getchannel(channelname)
		self:emit("mode", channel, setby, modes, params)
	elseif msg.command == "NOTICE" then
		local from = msg.nick
		local to = msg.args[1]
		local text = #msg.args > 1 and msg.args[2] or ""
		self:emit("notice", from, to, text)
	elseif msg.command == "TOPIC" then
		local setby = msg.nick
		local channel = msg.args[1]
		local topic = msg.args[2]
		self:emit("topic", channel, topic, setby)
	elseif msg.command == RPL.TOPIC or msg.command == RPL.NOTOPIC then
		local to = msg.args[1]
		local channelname = msg.args[2]
		local topic = msg.args[3]
		self:emit("topic", channelname, topic, nil)
	elseif msg.command == "KICK" then
		local kickedby = msg.nick
		local channel = msg.args[1]
		local kicked = msg.args[2]
		local reason = #msg.args >= 3 and msg.args[3] or nil
		local channel = self:getchannel(channelname)
		if self:isme(kicked) then
			self:removechannel(channelname)
		end
		self:emit("kick", channel, kicked, kickedby, reason)
	elseif msg.command == "KILL" then
		local killed = msg.args[1]
		if self:isme(killed) then
			self:_disconnected("Killed by the server")
		end
		self:emit("kill", killed)
	elseif msg.command == RPL.NAMREPLY then
		local to = msg.args[1]
		local channeltype = msg.args[2]
		local channelname = msg.args[3]
		local users = util.string.split(msg.args[4], " ")
		local channel = self:getchannel(channelname)
		for _,nick in ipairs(users) do
			local mode = Modes.getmodebyprefix(nick:sub(1,1))
			if mode ~= nil then
				nick = nick:sub(2)
			end
			channel:adduser(nick)
			if mode ~= nil then
				mode:set(channel, nil, {nick})
			end
		end
	elseif msg.command == RPL.ENDOFNAMES then
		local to = msg.args[1]
		local channelname = msg.args[2]
		local text = msg.args[3]
		local channel = self:getchannel(channelname)
		self:emit("names", channel)
	elseif msg.command == "INVITE" then
		local from = msg.nick
		local to = msg.args[1]
		local channel = msg.args[2]
		self:emit("invite", channel, from)
	elseif msg.command == "QUIT" then
		local whoquit = msg.nick
		local reason = msg.args[1]
		if self:isme(whoquit) then
			self:emit("iquit", reason)
			self:_disconnected("Quit: "..reason)
		end
		self:emit("quit", whoquit, reason)
	elseif msg.command == RPL.WELCOME then
		local actualnick = msg.args[1]
		self:_nickchanged(self.nick, actualnick)
		self:_connected(msg:lastarg(), msg.server)
	elseif msg.command == ERR.NICKNAMEINUSE then
		-- TODO: better handling of nickname in use/more options
		self.nick = self.nick.."_"
		self:send(Message:new("NICK", self.nick))
	elseif msg.command == RPL.ISUPPORT then
		for i,arg in ipairs(msg.args) do
			local key, value = arg:match("^([A-Z]+)=?(.*)$")
			if key == "CHANMODES" then
				local flagsbytype = util.string.split(value, ",")
				for flagtype, flagsstring in ipairs(flagsbytype) do
					flags = util.string.split(flagsstring, "")
					for _,flag in ipairs(flags) do
						Modes.add(flag, flagtype)
					end
				end
			elseif key == "PREFIX" then
				local flagsstring, prefixesstring = value:match("^%((.*)%)(.*)$")
				local flags = util.string.split(flagsstring, "")
				local prefixes = util.string.split(prefixesstring, "")
				assert(#flags==#prefixes)
				for i,flag in ipairs(flags) do
					Modes.add(flag, Modes.MODETYPE_USERPREFIX, prefixes[i])
				end
			end
		end
	elseif msg.command == RPL.MOTDSTART then
		self.motd = msg:lastarg().."\n"
	elseif msg.command == RPL.MOTD then
		self.motd = (self.motd or "")..msg:lastarg().."\n"
	elseif msg.command == RPL.ENDOFMOTD or msg.command == ERR.NOMOTD then
		self.motd = (self.motd or "")..msg:lastarg().."\n"
		self:emit("motd", self.motd)
	elseif msg.command == "ERROR" then
		self:_disconnected(msg:lastarg())
	elseif msg.command == "PONG" then
		self:emit("pong", unpack(msg.args))
	end
end

return IRC
