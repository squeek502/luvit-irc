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
local CTCP = require('./lib/constants').CTCP
local Handlers = require('./lib/handlers')

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
	self.connecting = false
	self.channels = {}
	self.retrycount = 0
	self.intentionaldisconnect = false

	if self.options.auto_connect then
		self:connect()
	end

	self:on("ikick", function(channel, kickedby, reason)
		if self.options.auto_rejoin then
			self:join(channel.name)
		end
	end)
	self:on("connect", function(welcomemsg)
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
		self:disconnect("Reconnecting")
	end

	if num_retries then
		print("Connect retry #"..num_retries.." to "..self.server)
	end

	dns.resolve4(self.server, function (err, addresses)
		if not addresses then
			self:emit("connecterror", "Could not resolve server address for "..tostring(self.server).." ("..tostring(err)..")", err)
			return
		end
		local resolvedip = addresses[1]
		if self.options.ssl then
			if not TLS then
				error ("luvit cannot require ('tls')")
			end
			TLS.connect (self.options.port, resolvedip, {}, function (err, client)
				self.sock = client
				self:_handlesock(client)
				self:_connect(self.nick, resolvedip)
			end)
		else
			local sock = TCP:new ()
			self.sock = sock
			sock:connect(resolvedip, self.options.port)
			self:_handlesock(sock)
			sock:on("connect", function ()
				sock:readStart()
				self:_connect(self.nick, resolvedip)
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
	end
	self:_disconnected(reason)
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

function IRC:_connect(nick, ip)
	self.intentionaldisconnect = false
	self.connecting = true
	if self.options.password ~= nil then
		self:send(Message:new("PASS", self.options.password))
	end
	self:send(Message:new("NICK", nick))
	local username = self.options.username or nick
	local modeflag = self.options.invisible and 8 or 0
	local unused_filler = "*"
	local real_name = self.options.real_name
	self:send(Message:new("USER", username, modeflag, unused_filler, real_name))
	self:emit("connecting", nick, self.server, username, real_name)
end

function IRC:_connected(welcomemsg, server)
	assert(not self.connected)
	self.connecting = false
	self.connected = true
	self:_clearchannels()
	Modes.clear()
	self:emit("connect", welcomemsg, server, self.nick)
end

function IRC:_disconnected(reason)
	local was_connected = self.connected
	local was_connecting = self.connecting
	self.connected = false
	self.connecting = false
	if was_connected then
		self:emit("disconnect", reason)

		if not self.intentionaldisconnect and self.auto_retry then
			self:connect(1)
		end
	elseif was_connecting then
		self:emit("connecterror", reason)
	end
end

function IRC:_toctcp(type, text)
	return CTCP.DELIM..type.." "..text..CTCP.DELIM
end

function IRC:_isctcp(text)
	return text:len() > 2 and text:sub(1,1) == CTCP.DELIM and text:sub(-1) == CTCP.DELIM
end

function IRC:_nickchanged(oldnick, newnick)
	if oldnick == newnick then return end
	if self:isme(oldnick) then
		self:emit("inick", oldnick, newnick)
		self.nick = newnick
	else
		self:emit("nick", oldnick, newnick)
	end
end

function IRC:_addchannel(channelname)
	assert(self:getchannel(channelname) == nil)
	local identifier = Channel.identifier(channelname)
	self.channels[identifier] = Channel:new(self, channelname)
end

function IRC:_removechannel(channelname)
	assert(self:getchannel(channelname) ~= nil)
	local identifier = Channel.identifier(channelname)
	self.channels[identifier]:destroy()
	self.channels[identifier] = nil
end

function IRC:_clearchannels()
	for identifier, channel in pairs(self.channels) do
		self:_removechannel(channel.name)
	end
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

	if Handlers[msg.command] then
		Handlers[msg.command](self, msg)
	else
		self:emit("unhandled", msg)
	end
end

return IRC
