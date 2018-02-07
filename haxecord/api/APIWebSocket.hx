package haxecord.api;
import haxecord.api.Client;
import haxecord.api.data.Channel;
import haxecord.api.data.Guild;
import haxecord.api.data.GuildChannel;
import haxecord.api.data.Member;
import haxecord.api.data.Message;
import haxecord.api.data.PrivateChannel;
import haxecord.api.data.Role;
import haxecord.api.data.User;
import haxecord.api.data.BaseChannel;
import haxecord.api.data.VoiceChannel;
import haxecord.api.data.VoiceState;
import haxecord.async.EventLoop;
import haxecord.async.Future;
import haxecord.http.URL;
import haxecord.nekows.AsyncWebSocket;
import haxecord.nekows.WebSocket;
import haxecord.nekows.WebSocketMessage;
import haxecord.utils.DateTime;


typedef BaseResponse = {
	var op:Int;
	var d:Dynamic;
	var s:Int;
	var t:String;
}

typedef HelloData = {
	var heartbeat_interval:Int;
	var _trace: Array<String>;
}

typedef ReadyPackage = {
	var v:Int;
	var user:Dynamic;
	var private_channels:Array<Dynamic>;
	var guilds:Array<Dynamic>;
	var session_id:String;
}

typedef TypingPackage = {
	var channel_id:String;
	var user_id:String;
	var timestamp:Int;
}

/**
 * ...
 * @author Billyoyo
 */
class APIWebSocket
{
	private var websocket:AsyncWebSocket;
	private var websocketFuture:Future;
	private var listeners:Array<APIEventListener> = new Array<APIEventListener>();
	private var heartbeatInterval:Float;
	private var lastHeartbeat:Float;
	private var heartbeatSequence:Int;
	private var client:Client;
	private var protocol:Int;
	
	private var shouldResume:Bool = false;
	private var resumeAttempts:Int = 0;
	
	public function new(client:Client, url:String, ?origin:String, ?timeperiod:Float) 
	{
		this.client = client;
		websocket = new AsyncWebSocket(new URL(url), origin, timeperiod);
		
		// handle heartbeat
		websocket.onUpdate = function(ws:WebSocket):Void {
			if (heartbeatInterval != null) {
				var left:Float = heartbeatInterval + lastHeartbeat - Sys.time();
				if (Sys.time() - lastHeartbeat >= heartbeatInterval) {
					sendHeartbeat();
					lastHeartbeat = Sys.time();
				}
			} else {  }
		};
		// handle messages
		websocket.onMessage = function(msg:WebSocketMessage):Void {
			try {
				var payload = msg.getJson();
				var response:BaseResponse = payload;
				if (response.s != null) heartbeatSequence = response.s;
				handleResponse(response);
			} catch ( source:Dynamic ) {
				trace('error encountered parsing message: ${msg.data}, $source\n\n');
			}
		};
		// not sure what to do on error, just print it for now
		websocket.onError = function(ws:WebSocket, source:Dynamic):Void {
			trace('error encountered in websocket: $source');
		};
		websocket.onClose = function(ws:WebSocket):Bool {
			resumeAttempts += 1;
			return (resumeAttempts < 3 && shouldResume);
		};
		websocket.onConnect = function(ws:WebSocket):Void {
			
		};
		websocket.onHandshake = function(ws:WebSocket):Void {
			if (!shouldResume) {
				websocket.sendJson({
					"op" : 2,
					"d" : {
							"token" : client.getToken(),
							"large_threshold" : 250,
							"compress" : false,
							"shard" : [client.getShard(), client.getShardCount()],
							"properties" : {
									"$os" : "Windows",
									"$browser" : "HaxeCord",
									"$device" : "HaxeCord",
									"$referrer" : "",
									"$referring_domain" : ""
							}
					}
				});
				shouldResume = true;
			} else {
				websocket.sendJson({
					"op": 6,
					"d" : {
						"token": client.getToken(),
						"session_id": client.sessionID,
						"seq": heartbeatSequence
					}
				});
			}
		}
		
	}
	
	public function start(loop:EventLoop)
	{
		websocketFuture = loop.addTask(websocket);
	}
	
	private function sendHeartbeat() {
		trace('sending sequence : $heartbeatSequence');
		websocket.sendJson({"op": 1, "d" : heartbeatSequence});
	}
	
	private function handleResponseDispatch(response:BaseResponse) {
		/* Events:
		*	 Ready, Resumed, Channel Create, Channel Update,
		*    Channel Delete, Guild Create, Guild Update,
		*    Guild Delete, Guild Ban Add, Guild Ban Remove,
		*    Guild Emojis Update, Guild Integrations Update,
		*    Guild Member Add, Guild Member Remove,
		*    Guild Member Update, Guild Members Chunk,
		*    Guild Role Create, Guild Role Update, Guild Role Delete,
		*    Message Create, Message Update, Message Delete,
		*    Message Delete Bulk, Presence Update, Typing Start,
		*    User Settings Update, User Update, Voice State Update,
		*    Voice Server Update
		*/ 
		var event:EventType = APIWebSocket.getEventType(response.t);
		dispatchEvent(event, response.d);
	}
	
	public function dispatchEvent(event:EventType, data:Dynamic) {
		if (event == EventType.READY) {
			var ready:ReadyPackage = data;
			client.me = new User(ready.user);
			protocol = ready.v;
			
			if (ready.private_channels != null) {
				for (rawChannel in ready.private_channels) {
					var channel:PrivateChannel = new PrivateChannel(rawChannel);
					client.privateChannels.set(channel.id, channel);
				}
			}
			
			if (ready.guilds != null) {
				for (rawGuild in ready.guilds) {
					var guild:Guild = new Guild(rawGuild);
					client.guilds.set(guild.id, guild);
				}
			}
			
			client.setSession(ready.session_id);
			for (listener in listeners) { listener.onReady(); }
		} else if (event == EventType.RESUMED) {
			resumeAttempts = 0;
			for (listener in listeners) { listener.onResume(); }
		} else if (event == EventType.CHANNEL_CREATE) {
			var channel:BaseChannel;
			if (BaseChannel.isPrivateChannel(data)) {
				var privateChannel:PrivateChannel = new PrivateChannel(data);
				client.privateChannels.set(privateChannel.id, privateChannel);
				channel = privateChannel;
			} else if (BaseChannel.isVoiceChannel(data)) {
				var guild:Guild = client.getGuild(BaseChannel.getGuildID(data));
				var voiceChannel:VoiceChannel = new VoiceChannel(guild, data);
				guild.voiceChannels.push(voiceChannel);
				channel = voiceChannel;
			} else {
				var guild:Guild = client.getGuild(BaseChannel.getGuildID(data));
				var textChannel:Channel = new Channel (guild, data);
				guild.channels.push(textChannel);
				channel = textChannel;
			}
			for (listener in listeners) { listener.onChannelCreate(channel); }
		} else if (event == EventType.CHANNEL_UPDATE) {
			var guildChan:GuildChannel = new GuildChannel(data);
			var guild:Guild = client.getGuild(guildChan.guildID);
			var returnChannel:BaseChannel;
			if (BaseChannel.isVoiceChannel(data)) {
				var channel:VoiceChannel = guild.getVoiceChannel(guildChan.id);
				if (channel != null) channel.updateData(data);
				returnChannel = channel;
			} else {
				var channel:Channel = guild.getChannel(guildChan.id);
				if (channel != null) channel.updateData(data);
				returnChannel = channel;
			}
			if (returnChannel != null) {
				for (listener in listeners) { listener.onChannelUpdate(returnChannel); }
			}	
		} else if (event == EventType.CHANNEL_DELETE) {
			var id:String = BaseChannel.getID(data);
			var channel:BaseChannel = null;
			if (BaseChannel.isPrivateChannel(data)) {
				channel = client.privateChannels.get(id);
				client.privateChannels.remove(id);
			} else {
				var guild:Guild = client.getGuild(BaseChannel.getGuildID(data));
				if (guild != null) {
					if (BaseChannel.isVoiceChannel(data)) {
						var voiceChannel:VoiceChannel = guild.getVoiceChannel(id);
						if (voiceChannel != null) guild.voiceChannels.remove(voiceChannel);
						channel = voiceChannel;
					} else {
						var textChannel:Channel = guild.getChannel(id);
						if (textChannel != null) guild.channels.remove(textChannel);
						channel = textChannel;
					}
				}
			}
			if (channel != null) {
				for (listener in listeners) { listener.onChannelDelete(channel); }
			}
		} else if (event == EventType.GUILD_CREATE) {
			var guild:Guild = new Guild(data);
			if (client.guilds.exists(guild.id)) {
				// intial guild packets, no need to call an event
				client.guilds.set(guild.id, guild);
			} else {
				// we have joined a new guild, or similar
				client.guilds.set(guild.id, guild);
				for (listener in listeners) { listener.onGuildJoin(guild); }
			}
		} else if (event == EventType.GUILD_UPDATE) {
			var guild:Guild = client.getGuild(BaseChannel.getID(data));
			if (guild != null) {
				guild.parseData(guild);
				for (listener in listeners) { listener.onGuildUpdate(guild); }
			}
		} else if (event == EventType.GUILD_DELETE) {
			var guild:Guild = client.getGuild(BaseChannel.getID(data));
			if (guild != null) {
				if (Guild.guildUnavailable(data)) {
					// guild made unavailable
					guild.parseData(data);
					for (listener in listeners) { listener.onGuildDisconnect(guild); }
				} else {
					// client removed from the guild
					client.guilds.remove(guild.id);
					for (listener in listeners) { listener.onGuildLeave(guild); }
				}
			}
		} else if (event == EventType.GUILD_BAN_ADD) {
			var guild:Guild = client.getGuild(BaseChannel.getGuildID(data));
			if (guild != null) {
				var user:User = new User(data);
				
				for (listener in listeners) { listener.onBan(guild, user); }
			}
		} else if (event == EventType.GUILD_BAN_REMOVE) {
			var guild:Guild = client.getGuild(BaseChannel.getGuildID(data));
			if (guild != null) {
				var user:User = new User(data);
				
				for (listener in listeners) { listener.onUnban(guild, user); }
			}
		} else if (event == EventType.GUILD_EMOJIS_UPDATE) {
			var guild:Guild = client.getGuild(BaseChannel.getGuildID(data));
			if (guild != null) {
				guild.updateEmojis(data);
				
				for (listener in listeners) { listener.onEmojisUpdated(guild); }
			}
		} else if (event == EventType.GUILD_INTEGRATIONS_UPDATE) {
			var guild:Guild = client.getGuild(BaseChannel.getGuildID(data));
			if (guild != null) {
				for (listener in listeners) { listener.onIntegrationsUpdated(guild); }
			}
		} else if (event == EventType.GUILD_MEMBER_ADD) {
			var guild:Guild = client.getGuild(BaseChannel.getGuildID(data));
			if (guild != null) {
				var member:Member = new Member(guild, data);
				guild.members.push(member);
				for (listener in listeners) { listener.onMemberJoin(member); }
			}
		} else if (event == EventType.GUILD_MEMBER_REMOVE) {
			var guild:Guild = client.getGuild(BaseChannel.getGuildID(data));
			if (guild != null) {
				var user:User = User.fromData(data);
				var member:Member = guild.getMember(user.id);
				if (member != null) guild.members.remove(member);
				
				for (listener in listeners) { listener.onMemberLeave(guild, user); }
			}
		} else if (event == EventType.GUILD_MEMBER_UPDATE) {
			var guild:Guild = client.getGuild(BaseChannel.getGuildID(data));
			if (guild != null) {
				var member:Member = guild.updateMember(data);
				if (member != null) {
					for (listener in listeners) { listener.onMemberUpdate(member); }
				}
			}
		} else if (event == EventType.GUILD_MEMBERS_CHUNK) {
			var guild:Guild = client.getGuild(BaseChannel.getGuildID(data));
			if (guild != null) {
				guild.loadMembersChunk(data);
				// possibly make event?
			}
		} else if (event == EventType.GUILD_ROLE_CREATE) {
			var guild:Guild = client.getGuild(BaseChannel.getGuildID(data));
			if (guild != null) {
				var role:Role = guild.createRole(data);
				for (listener in listeners) { listener.onRoleCreate(guild, role); }
			}
		} else if (event == EventType.GUILD_ROLE_UPDATE) {
			var guild:Guild = client.getGuild(BaseChannel.getGuildID(data));
			if (guild != null) {
				var role:Role = guild.updateRole(data);
				for (listener in listeners) { listener.onRoleUpdate(guild, role); }
			}
		} else if (event == EventType.GUILD_ROLE_DELETE) {
			var guild:Guild = client.getGuild(BaseChannel.getGuildID(data));
			if (guild != null) {
				var role:Role = guild.getRole(Role.getRoleID(data));
				if (role != null) {
					guild.roles.remove(role);
					for (listener in listeners) { listener.onRoleDelete(guild, role); }
				}
			}
		} else if (event == EventType.MESSAGE_CREATE) {
			var message:Message = new Message(client, data);
			client.storeMessage(message);
			for (listener in listeners) { listener.onMessage(message); }
		} else if (event == EventType.MESSAGE_UPDATE) {
			var message:Message = client.getMessage(BaseChannel.getID(data));
			if (message != null) {
				message.updateMessageData(client, data);
				for (listener in listeners) { listener.onMessageEdit(message); }
			}
		} else if (event == EventType.MESSAGE_DELETE) {
			var message:Message = client.getMessage(BaseChannel.getID(data));
			if (message != null) {
				client.unstoreMessage(message);
				for (listener in listeners) { listener.onMessageDelete(message); }
			}
		} else if (event == EventType.MESSAGE_DELETE_BULK) {
			var ids:Array<String> = Message.getIDs(data);
			var message:Message;
			for (id in ids) {
				var message:Message = client.getMessage(id);
				if (message != null) {
					client.unstoreMessage(message);
					for (listener in listeners) { listener.onMessageDelete(message); }
				}
			}
		} else if (event == EventType.TYPING_START) {
			var typing:TypingPackage = data;
			var channel:Channel = client.getChannel(typing.channel_id);
			var timestamp:DateTime = null;
			if (typing.timestamp != null) timestamp = DateTime.fromFloat(typing.timestamp);
			if (channel != null) {
				var member:Member = channel.guild.getMember(typing.user_id);
				if (member != null) {
					for (listener in listeners) { listener.onTyping(channel, member, timestamp); }
				}
			}
		} else if (event == EventType.USER_UPDATE) {
			var user:User = new User(data);
			if (user.id == client.me.id) {
				client.me.parseData(data);
				user = client.me;
			}
			for (listener in listeners) { listener.onUserUpdate(user); }
		} else if (event == EventType.VOICE_STATE_UPDATE) {
			var guild:Guild = null;
			try {
				guild = client.getGuild(BaseChannel.getGuildID(data));
			} catch (source:Dynamic) {
				var channel:VoiceChannel = client.getVoiceChannel(BaseChannel.getChannelID(data));
				if (channel != null) {
					guild = channel.guild;
				}
			}
			
			if (guild != null) {
				var voiceState:VoiceState = guild.updateVoiceState(data);
				if (voiceState != null) {
					for (listener in listeners) { listener.onVoiceStateUpdate(voiceState); }
				}
			}
		} else if (event == EventType.VOICE_SERVER_UPDATE) {
			var guild:Guild = client.getGuild(BaseChannel.getGuildID(data));
			if (guild != null) {
				guild.updateVoiceServer(data);
				for (listener in listeners) { listener.onVoiceServerUpdate(guild); }
			}
		} else if (event == EventType.PRESENCE_UPDATE) {
			try {
				var guild:Guild = client.getGuild(BaseChannel.getGuildID(data));
				if (guild != null) {
					var member:Member = guild.updatePresence(data);
					for (listener in listeners) { listener.onStatusUpdate(member); }
				}
			} catch (source:Dynamic) {
				var user:User = User.fromData(data);
				for (member in client.getMembers(user.id)) {
					member.guild.updatePresence(data);
				}
				for (listener in listeners) { listener.onStatusUpdate(user); }
			}
		}
		
		/* TODO: 
		 *    User Settings Update event - don't know what to do with this
		 */ 
	}
	
	
	
	private function handleResponseReconnect(response:BaseResponse) {
		trace("told to reconnect, disconnecting");
		// will handle reconnect logic later
		websocket.disconnect();
	}
	
	private function handleResponseHello(response:BaseResponse) {
		var data:HelloData = response.d;
		heartbeatInterval = data.heartbeat_interval / 1000;
		lastHeartbeat = Sys.time();
		trace('hello recieved $heartbeatInterval | ${data.heartbeat_interval}');
	}
	
	private function handleResponseInvalidSession(response:BaseResponse) {
		trace("invalid session, disconnecting");
		shouldResume = false;
		// completely reconnect the websocket
		websocket.disconnect();
		websocket.connect();
	}
	
	private function handleResponseHeartbeatACK(response:BaseResponse) {
		trace("hearbeat ack recieved");
	}
	
	private function handleResponse(response:BaseResponse) {
		switch(response.op) {
			case 0: handleResponseDispatch(response);       // dispatch event
			case 7: handleResponseReconnect(response);      // reconnect
			case 9: handleResponseInvalidSession(response); // invalid session
			case 10: handleResponseHello(response);         // hello
			case 11: handleResponseHeartbeatACK(response);  // heartbeat ack
			default: 0;
		}
	}
	
	public function addListener(listener:APIEventListener):APIWebSocket {
		listeners.push(listener);
		return this;
	}
	
	public function addListeners(listeners:Array<APIEventListener>):APIWebSocket {
		this.listeners = this.listeners.concat(listeners);
		return this;
	}
	
	public function removeListener(listener:APIEventListener):APIWebSocket {
		listeners.remove(listener);
		return this;
	}
	
	public static function getEventType(eventName:String):EventType
	{
		return switch(eventName) {
			case "READY": EventType.READY;
			case "RESUMED": EventType.RESUMED;
			case "CHANNEL_CREATE": EventType.CHANNEL_CREATE;
			case "CHANNEL_UPDATE": EventType.CHANNEL_UPDATE;
			case "CHANNEL_DELETE": EventType.CHANNEL_DELETE;
			case "GUILD_CREATE": EventType.GUILD_CREATE;
			case "GUILD_UPDATE": EventType.GUILD_UPDATE;
			case "GUILD_DELETE": EventType.GUILD_DELETE;
			case "GUILD_BAN_ADD": EventType.GUILD_BAN_ADD;
			case "GUILD_BAN_REMOVE": EventType.GUILD_BAN_REMOVE;
			case "GUILD_EMOJIS_UPDATE": EventType.GUILD_EMOJIS_UPDATE;
			case "GUILD_INTEGRATIONS_UPDATE": EventType.GUILD_INTEGRATIONS_UPDATE;
			case "GUILD_MEMBER_ADD": EventType.GUILD_MEMBER_ADD;
			case "GUILD_MEMBER_REMOVE": EventType.GUILD_MEMBER_REMOVE;
			case "GUILD_MEMBER_UPDATE": EventType.GUILD_MEMBER_UPDATE;
			case "GUILD_MEMBERS_CHUNK": EventType.GUILD_MEMBERS_CHUNK;
			case "GUILD_ROLE_CREATE": EventType.GUILD_ROLE_CREATE;
			case "GUILD_ROLE_UPDATE": EventType.GUILD_ROLE_UPDATE;
			case "GUILD_ROLE_DELETE": EventType.GUILD_ROLE_DELETE;
			case "MESSAGE_CREATE": EventType.MESSAGE_CREATE;
			case "MESSAGE_UPDATE": EventType.MESSAGE_UPDATE;
			case "MESSAGE_DELETE": EventType.MESSAGE_DELETE;
			case "MESSAGE_DELETE_BULK": EventType.MESSAGE_DELETE_BULK;
			case "PRESENCE_UPDATE": EventType.PRESENCE_UPDATE;
			case "TYPING_START": EventType.TYPING_START;
			case "USER_SETTINGS_UPDATE": EventType.USER_SETTINGS_UPDATE;
			case "USER_UPDATE": EventType.USER_UPDATE;
			case "VOICE_STATE_UPDATE": EventType.VOICE_STATE_UPDATE;
			case "VOICE_SERVER_UPDATE": EventType.VOICE_SERVER_UPDATE;
			default: EventType.UNKNOWN;
		}
	}
	
}