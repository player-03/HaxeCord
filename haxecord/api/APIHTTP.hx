package haxecord.api;
import haxecord.api.data.BaseChannel;
import haxecord.api.data.BaseChannel.VoiceChannelCheck;
import haxecord.api.data.Channel;
import haxecord.api.data.Guild;
import haxecord.api.data.GuildEmbed;
import haxecord.api.data.Integration;
import haxecord.api.data.Invite;
import haxecord.api.data.Member;
import haxecord.api.data.Message;
import haxecord.api.data.PrivateChannel;
import haxecord.api.data.Role;
import haxecord.api.data.User;
import haxecord.api.data.UserConnection;
import haxecord.api.data.UserGuild;
import haxecord.api.data.VoiceChannel;
import haxecord.api.data.VoiceRegion;
import haxecord.async.EventLoop;
import haxecord.async.Future;
import haxecord.http.HTTP;
import haxecord.http.HTTPException;
import haxecord.http.HTTPRequest;
import haxecord.http.HTTPResponse;


typedef PrunedPackage = {
	var pruned:Int;
}

/**
 * ...
 * @author Billyoyo
 */
class APIHTTP extends HTTP
{
	
	private var client:Client;
	
	public function new(client:Client, ?loop:EventLoop)
	{
		super(loop);
		this.client = client;
	}
	
	public function callAPI(method:String, target:String, data:Dynamic, ?callback:HTTPResponse->Void, ?error:HTTPException->Void):Future
	{
		if (data != null) {
			return request(method.toUpperCase(), "https://discordapp.com/api/" + target, {
				"headers": [ "Authorization" => 'Bot ${client.token}' ],
				"json": data,
				"onComplete" : function(req:HTTPRequest , resp:HTTPResponse) { if (callback != null) callback(resp); },
				"onError": function(req:HTTPRequest, httperror:HTTPException) { if (error != null) error(httperror);  }
			});
		} else {
			return request(method.toUpperCase(), "https://discordapp.com/api/" + target, {
				"headers": [ 
					"Authorization" => 'Bot ${client.token}',
					"Content-Type" => "application/json",
				],
				"onComplete" : function(req:HTTPRequest , resp:HTTPResponse) { if (callback != null) callback(resp); },
				"onError": function(req:HTTPRequest, httperror:HTTPException) { if (error != null) error(httperror);  }
			});
		}
	}

	public function getChannel(channelID:String, ?callback:BaseChannel->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'channels/$channelID', null, function(resp:HTTPResponse) {
			var data:Dynamic = resp.getJson();
			if (BaseChannel.isPrivateChannel(data)) {
				var channel:PrivateChannel = new PrivateChannel(data);
				client.privateChannels.set(channel.id, channel);
				if (callback != null) callback(channel);
			} else {
				var guild:Guild = client.getGuild(BaseChannel.getGuildID(data));
				if (guild != null) {
					var channel:Channel = new Channel(guild, data);
					if (!guild.hasChannel(channel.id)) guild.channels.push(channel);
					if (callback != null) callback(channel);
				} else {
					if (error != null) error(new HTTPException(data, "guild not found in storage", 0));
				}
			}
		}, error);
	}
	
	public function modifyChannel(channelID:String, data:Dynamic, ?callback:BaseChannel->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("put", 'channels/$channelID', data, function(resp:HTTPResponse) {
			var data:Dynamic = resp.getJson();
			var guild:Guild = client.getGuild(BaseChannel.getGuildID(data));
			if (guild != null) {
				if (BaseChannel.isVoiceChannel(data)) {
					var channel:VoiceChannel = guild.getVoiceChannel(BaseChannel.getID(data));
					if (channel == null) {
						channel = new VoiceChannel(guild, data);
						guild.voiceChannels.push(channel);
					} else {
						channel.updateData(data);
					}
					if (callback != null) callback(channel);
				} else {
					var channel:Channel = guild.getChannel(BaseChannel.getID(data));
					if (channel == null) {
						channel = new Channel(guild, data);
						guild.channels.push(channel);
					} else {
						channel.updateData(data);
					}
					if (callback != null) callback(channel);
				}
			} else {
				if (error != null) error(new HTTPException(data, "guild not found in storage", 0));
			}
		}, error);
	}
	
	public function deleteChannel(channelID:String, ?callback:BaseChannel->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("delete", 'channels/$channelID', null, function(resp:HTTPResponse) {
			var data:Dynamic = resp.getJson();
			if (BaseChannel.isPrivateChannel(data)) {
				var channel:PrivateChannel = new PrivateChannel(data);
				client.privateChannels.remove(channel.id);
				if (callback != null) callback(channel);
			} else {
				var guild:Guild = client.getGuild(BaseChannel.getGuildID(data));
				if (guild != null) {
					if (BaseChannel.isVoiceChannel(data)) {
						var channel:Channel = new Channel(guild, data);
						
						var oldChannel:Channel = guild.getChannel(channel.id);
						if (oldChannel != null) {
							channel = oldChannel;
							guild.channels.remove(oldChannel);
						}
						
						if (callback != null) callback(channel);
					} else {
						var channel:VoiceChannel = new VoiceChannel(guild, data);
						
						var oldChannel:VoiceChannel = guild.getVoiceChannel(channel.id);
						if (oldChannel != null) {
							channel = oldChannel;
							guild.voiceChannels.remove(oldChannel);
						}
						
						if (callback != null) callback(channel);
					}
				} else { 
					if (error != null) error(new HTTPException(data, "guild not found in storage", 0));
				}
			}
		}, error);
	}
	
	public function getMessages(channelID:String, data:Dynamic, ?callback:Array<Message>->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'channels/$channelID/messages', null, function(resp:HTTPResponse) {
			if (callback != null) {
				var data:Array<Dynamic> = resp.getJson();
				var messages:Array<Message> = new Array<Message>();
				for (rawMessage in data) {
					messages.push(new Message(client, rawMessage));
				}
				callback(messages);
			}
		}, error);
	}
	
	public function getMessage(channelID:String, messageID:String, ?callback:Message->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'channels/$channelID/messages/$messageID', null, function (resp:HTTPResponse) {
			if (callback != null) {
				callback(new Message(client, resp.getJson()));
			}
		}, error);
	}
	
	public function createMessage(channelID:String, data:Dynamic, ?callback:Message->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("post", 'channels/$channelID/messages', data, function (resp:HTTPResponse) {
			if (callback != null) {
				callback(new Message(client, resp.getJson()));
			}
		}, error);
	}
	
	public function createReaction(channelID:String, messageID:String, emoji:String, ?callback:Void->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("put", 'channels/$channelID/messages/$messageID/reactions/$emoji/@me', null, function (resp:HTTPResponse)
		{
			if (callback != null) callback();
		}, error);
	}
	
	public function deleteOwnReaction(channelID:String, messageID:String, emoji:String, ?callback:Void->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("delete", 'channels/$channelID/messages/$messageID/reactions/$emoji/@me', null, function (resp:HTTPResponse) {
			if (callback != null) callback();
		}, error);
	}
	
	public function deleteUserReaction(channelID:String, messageID:String, emoji:String, userID:String, ?callback:Void->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("delete", 'channels/$channelID/messages/$messageID/reactions/$emoji/$userID', null, function(resp:HTTPResponse) {
			if (callback != null) callback();
		}, error);
	}
	
	public function getReactions(channelID:String, messageID:String, emoji:String, ?callback:Array<Member>->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'channels/$channelID/messages/$messageID/reactions/$emoji', null, function(resp:HTTPResponse) {
			var data:Array<Dynamic> = resp.getJson();
			var channel:Channel = client.getChannel(channelID);
			var members:Array<Member> = new Array<Member>();
			for (rawUser in data) {
				var member:Member = null;
				if (channel != null) {
					member = channel.guild.getMember(BaseChannel.getID(rawUser));
					if (member == null) { 
						member = new Member(channel.guild, rawUser);
						channel.guild.members.push(member);
					}
				} else {
					member = new Member(null, rawUser, true);
				}
				members.push(member);
			}
			if (callback != null) callback(members);
		}, error);
	}
	
	public function deleteReactions(channelID:String, messageID:String, ?callback:Void->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("delete", 'channels/$channelID/messages/$messageID/reactions', null, function(resp:HTTPResponse) {
			if (callback != null) callback();
		}, error);
	}
	
	public function editMessage(channelID:String, messageID:String, data:Dynamic, ?callback:Message->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("patch", 'channels/$channelID/messages/$messageID', data, function (resp:HTTPResponse) {
			if (callback != null) callback(new Message(client, resp.getJson()));
		}, error);
	}
	
	public function deleteMessage(channelID:String, messageID:String, ?callback:Void->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("delete", 'channels/$channelID/messages/$messageID', null, function (resp:HTTPResponse) {
			if (callback != null) callback();
		}, error);
	}
	
	public function bulkDeleteMessages(channelID:String, data:Dynamic, ?callback:Void->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("post", 'channels/$channelID/messages/bulk-delete', data, function (resp:HTTPResponse) {
			if (callback != null) callback();
		}, error);
	}
	
	public function editChannelPermissions(channelID:String, overwriteID:String, data:Dynamic, ?callback:Void->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("put", 'channels/$channelID/permissions/$overwriteID', data, function (resp:HTTPResponse) {
			if (callback != null) callback();
		}, error);
	}
	
	public function getChannelInvites(channelID:String, ?callback:Array<Invite>->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'channels/$channelID/invites', null, function (resp:HTTPResponse) {
			if (callback != null) {
				var data:Array<Dynamic> = resp.getJson();
				var invites:Array<Invite> = new Array<Invite>();
				for (rawInvite in data) {
					invites.push(new Invite(rawInvite));
				}
				callback(invites);
			}
		}, error);
	}
	
	public function createChannelInvite(channelID:String, data:Dynamic, ?callback:Invite->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("post", 'channels/$channelID/invites', data, function (resp:HTTPResponse) {
			if (callback != null) {
				callback(new Invite(resp.getJson()));
			}
		}, error);
	}
	
	public function deleteChannelPermission(channelID:String, overwriteID:String, ?callback:Void->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("delete", 'channels/$channelID/permissions/$overwriteID', null, function (resp:HTTPResponse) {
			if (callback != null) callback();
		}, error);
	}
	
	public function triggerTyping(channelID:String, ?callback:Void->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("post", 'channels/$channelID/typing', null, function (resp:HTTPResponse) {
			if (callback != null) callback();
		}, error);
	}
	
	public function getPinned(channelID:String, ?callback:Array<Message>->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'channels/$channelID/pins', null, function (resp:HTTPResponse) {
			if (callback != null) {
				var data:Array<Dynamic> = resp.getJson();
				var messages:Array<Message> = new Array<Message>();
				for (rawMessage in data) {
					messages.push(new Message(client, rawMessage));
				}
				callback(messages);
			}
		}, error);
	}
	
	public function addPin(channelID:String, messageID:String, ?callback:Void->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("put", 'channels/$channelID/pins/$messageID', null, function(resp:HTTPResponse) {
			if (callback != null) callback();
		}, error);
	}
	
	public function deletePin(channelID:String, messageID:String, ?callback:Void->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("delete", 'channels/$channelID/pins/$messageID', null, function (resp:HTTPResponse) {
			if (callback != null) callback();
		}, error);
	}
	
	public function getGuild(guildID:String, ?callback:Guild->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'guilds/$guildID', null, function (resp:HTTPResponse) {
			var data:Dynamic = resp.getJson();
			var guild:Guild = client.getGuild(BaseChannel.getID(data));
			if (guild == null) {
				guild = new Guild(data);
				client.guilds.set(guild.id, guild);
			}
			if (callback != null) callback(guild);
		}, error);
	}
	
	public function modifyGuild(guildID:String, data:Dynamic, ?callback:Guild->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("patch", 'guilds/$guildID', null, function (resp:HTTPResponse) {
			var data:Dynamic = resp.getJson();
			var guild:Guild = client.getGuild(BaseChannel.getID(data));
			if (guild != null) {
				guild.parseData(data);
			} else {
				guild = new Guild(data);
				client.guilds.set(guild.id, guild);
			}
			if (callback != null) callback(guild);
		}, error);
	}
	
	public function deleteGuild(guildID:String, ?callback:Guild->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("delete", 'guilds/$guildID', null, function (resp:HTTPResponse) {
			var data:Dynamic = resp.getJson();
			var guild:Guild = client.getGuild(BaseChannel.getID(data));
			if (guild != null) {
				client.guilds.remove(guild.id);
			} else {
				guild = new Guild(data);
			}
			if (callback != null) callback(guild);
		}, error);
	}
	
	public function getGuildChannels(guildID:String, ?callback:Array<BaseChannel>->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'guilds/$guildID/channels', null, function (resp:HTTPResponse) {
			var data:Array<Dynamic> = resp.getJson();
			if (data.length > 0) {
				var guild = client.getGuild(BaseChannel.getGuildID(data[0]));
				if (guild != null) {
					var channels:Array<BaseChannel> = new Array<BaseChannel>();
					for (rawChannel in data) {
						if (BaseChannel.isVoiceChannel(rawChannel)) {
							var voiceChannel:VoiceChannel = guild.getVoiceChannel(BaseChannel.getID(rawChannel));
							if (voiceChannel == null) {
								voiceChannel = new VoiceChannel(guild, rawChannel);
								guild.voiceChannels.push(voiceChannel);
							}
							channels.push(voiceChannel);
						} else {
							var channel:Channel = guild.getChannel(BaseChannel.getID(rawChannel));
							if (channel == null) {
								channel = new Channel(guild, rawChannel);
								guild.channels.push(channel);
							}
							channels.push(channel);
						}
					}
					if (callback != null) callback(channels);
				} else {
					if (error != null) error(new HTTPException(data, "couldn't find guild in storage", 0));
				}
			} else {
				if (callback != null) callback(new Array<BaseChannel>());
			}
		}, error);
	}
	
	public function createGuildChannel(guildID:String, data:Dynamic, ?callback:BaseChannel->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("post", 'guilds/$guildID/channels', data, function (resp:HTTPResponse) {
			var data:Dynamic = resp.getJson();
			var guild:Guild = client.getGuild(BaseChannel.getGuildID(data));
			if (guild != null) {
				if (BaseChannel.isVoiceChannel(data)) {
					var channel:VoiceChannel = new VoiceChannel(guild, data);
					guild.voiceChannels.push(channel);
					if (callback != null) callback(channel);
				} else {
					var channel:Channel = new Channel(guild, data);
					guild.channels.push(channel);
					if (callback != null) callback(channel);
				}
			} else {
				if (error != null) error(new HTTPException(data, "couldn't find guild in storage", 0));
			}
		}, error);
	}
	
	public function modifyGuildChannelPositions(guildID:String, data:Dynamic, ?callback:Void->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("patch", 'guilds/$guildID/channels', data, function(resp:HTTPResponse) {
			if (callback != null) callback();
		}, error);
	}
	
	public function getGuildMember(guildID:String, userID:String, ?callback:Member->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'guilds/$guildID/members/$userID', null, function (resp:HTTPResponse) {
			var data:Dynamic = resp.getJson();
			var guild:Guild = client.getGuild(guildID);
			if (guild != null) {
				var member:Member = guild.getMember(userID);
				
				if (member == null) {
					member = new Member(guild, data);
					guild.members.push(member);
				}
				
				if (callback != null) callback(member);
			} else {
				if (callback != null) callback(new Member(null, data, true));
			}
		}, error);
	}
	
	public function listGuildMembers(guildID:String, data:Dynamic, ?callback:Array<Member>->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'guilds/$guildID/members', data, function (resp:HTTPResponse) {
			var data:Array<Dynamic> = resp.getJson();
			var guild:Guild = client.getGuild(guildID);
			var members:Array<Member> = new Array<Member>();
			if (guild != null) {
				for (rawMember in data) {
					var member:Member = guild.getMember(BaseChannel.getID(rawMember));
					if (member == null) {
						member = new Member(guild, rawMember);
						guild.members.push(member);
					}
					members.push(member);
				}
			} else {
				for (rawMember in data) {
					members.push(new Member(null, rawMember, true));
				}
			}
			if (callback != null) callback(members);
		}, error);
	}
	
	public function addGuildMember(guildID:String, userID:String, data:Dynamic, ?callback:Member->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("put", 'guilds/$guildID/members/$userID', data, function (resp:HTTPResponse) {
			var data:Dynamic = resp.getJson();
			var guild:Guild = client.getGuild(guildID);
			if (guild != null) {
				var member:Member = guild.getMember(BaseChannel.getID(data));
				
				if (member == null) {
					member = new Member(guild, data);
					guild.members.push(member);
				}
				if (callback != null) callback(member);
			}
		}, error);
	}
	
	public function modifyGuildMember(guildID:String, userID:String, data:Dynamic, ?callback:Void->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("patch", 'guilds/$guildID/members/$userID', data, function(resp:HTTPResponse) {
			if (callback != null) callback();
		}, error);
	}
	
	public function removeGuildMember(guildID:String, userID:String, ?callback:Void->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("delete", 'guilds/$guildID/members/$userID', null, function (resp:HTTPResponse) {
			if (callback != null) callback();
		}, error);
	}
	
	public function getGuildBans(guildID:String, ?callback:Array<User>->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'guilds/$guildID/bans', null, function (resp:HTTPResponse) {
			if (callback != null) {
				var data:Array<Dynamic> = resp.getJson();
				var users:Array<User> = new Array<User>();
				for (rawUser in data) {
					users.push(new User(rawUser));
				}
				callback(users);
			}
		}, error);
	}
	
	public function createGuildBan(guildID:String, userID:String, data:Dynamic, ?callback:Void->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("put", 'guilds/$guildID/bans/$userID', data, function (resp:HTTPResponse) {
			if (callback != null) callback();
		}, error);
	}
	
	public function removeGuildBan(guildID:String, userID:String, ?callback:Void->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("delete", 'guilds/$guildID/bans/$userID', null, function (resp:HTTPResponse) {
			if (callback != null) callback();
		}, error);
	}
	
	public function getGuildRoles(guildID:String, ?callback:Array<Role>->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'guilds/$guildID/roles', null, function (resp:HTTPResponse) {
			if (callback != null) {
				var data:Array<Dynamic> = resp.getJson();
				var roles:Array<Role> = new Array<Role>();
				for (rawRole in data) {
					roles.push(new Role(rawRole));
				}
				callback(roles);
			}
		}, error);
	}
	
	public function createGuildRole(guildID:String, ?callback:Role->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("post", 'guilds/$guildID/roles', null, function (resp:HTTPResponse) {
			var data:Dynamic = resp.getJson();
			var role:Role = new Role(data);
			var guild:Guild = client.getGuild(guildID);
			if (guild != null) guild.roles.push(role);
			if (callback != null) callback(role);
		}, error);
	}
	
	public function modifyGuildRolePositions(guildID:String, data:Dynamic, ?callback:Void->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("patch", 'guilds/$guildID/roles', data, function (resp:HTTPResponse) {
			if (callback != null) callback();
		}, error);
	}
	
	public function modifyGuildRole(guildID:String, roleID:String, data:Dynamic, ?callback:Role->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("patch", 'guilds/$guildID/roles/$roleID', data, function (resp:HTTPResponse) {
			var data:Dynamic = resp.getJson();
			var guild:Guild = client.getGuild(guildID);
			if (guild != null) {
				var role:Role = guild.getRole(BaseChannel.getID(data));
				if (role == null) {
					role = new Role(data);
					guild.roles.push(role);
				} else {
					role.parseData(data);
				}
				if (callback != null) callback(role);
			} else {
				if (callback != null) callback(new Role(data));
			}
		}, error);
	}
	
	public function deleteGuildRole(guildID:String, roleID:String, data:Dynamic, ?callback:Role->Void, ?error:HTTPException->Void):Future
	{
		return callAPI("delete", 'guilds/$guildID/roles/$roleID', data, function (resp:HTTPResponse) {
			var data:Dynamic = resp.getJson();
			
			var role:Role = null;
			var guild:Guild = client.getGuild(guildID);
			if (guild != null) {
				role = guild.getRole(BaseChannel.getID(data));
				if (role != null) guild.roles.remove(role);
			}
			if (callback != null) {
				if (role == null) role = new Role(data);
				callback(role);
			}
		}, error);
	}
	
	public function getGuildPruneCount(guildID:String, data:Dynamic, ?callback:Int-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'guilds/$guildID/prune', data, function (resp:HTTPResponse) {
			if (callback != null) {
				var data:PrunedPackage = resp.getJson();
				callback(data.pruned);
			}
		}, error);
	}
	
	public function beginGuildPrune(guildID:String, data:Dynamic, ?callback:Int-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("post", 'guilds/$guildID/prune', data, function (resp:HTTPResponse) {
			if (callback != null) {
				var data:PrunedPackage = resp.getJson();
				callback(data.pruned);
			}
		}, error);
	}
	
	public function getGuildVoiceRegions(guildID:String, ?callback:Array<VoiceRegion>-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'guilds/$guildID/regions', null, function (resp:HTTPResponse) {
			if (callback != null) {
				var data:Array<Dynamic> = resp.getJson();
				var regions:Array<VoiceRegion> = new Array<VoiceRegion>();
				for (rawRegion in data) {
					regions.push(new VoiceRegion(rawRegion));
				}
				callback(regions);
			}
		}, error); 
	}
	
	public function getGuildInvites(guildID:String, ?callback:Array<Invite>-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'guilds/$guildID/invites', null, function (resp:HTTPResponse) {
			if (callback != null) {
				var data:Array<Dynamic> = resp.getJson();
				var invites:Array<Invite> = new Array<Invite>();
				for (rawInvite in data) {
					invites.push(new Invite(rawInvite));
				}
				callback(invites);
			}
		}, error);
	}
	
	public function getGuildIntegrations(guildID:String, ?callback:Array<Integration>-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'guilds/$guildID/integrations', null, function (resp:HTTPResponse) {
			if (callback != null) {
				var data:Array<Dynamic> = resp.getJson();
				var integrations:Array<Integration> = new Array<Integration>();
				for (rawIntegration in data) {
					integrations.push(new Integration(rawIntegration));
				}
				callback(integrations);
			}
		}, error);
	}
	
	public function createGuildIntegration(guildID:String, data, ?callback:Void-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("post", 'guilds/$guildID/integrations', data, function (resp:HTTPResponse) {
			if (callback != null) callback();
		}, error);
	}
	
	public function modifyGuildIntegration(guildID:String, integrationID:String, data:Dynamic, ?callback:Void-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("patch", 'guilds/$guildID/integrations/$integrationID', data, function (resp:HTTPResponse) {
			if (callback != null) callback();
		}, error);
	}
	
	public function deleteGuildIntegration(guildID:String, integrationID:String, ?callback:Void-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("delete", 'guilds/$guildID/integrations/$integrationID', null, function (resp:HTTPResponse) {
			if (callback != null) callback();
		}, error);
	}
	
	public function syncGuildIntegration(guildID:String, integrationID:String, ?callback:Void-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("post", 'guilds/$guildID/integrations/$integrationID/sync', null, function (resp:HTTPResponse) {
			if (callback != null) callback();
		}, error);
	}
	
	public function getGuildEmbed(guildID:String, ?callback:GuildEmbed-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'guilds/$guildID/embed', null, function (resp:HTTPResponse) {
			if (callback != null) {
				var data:Dynamic = resp.getJson();
				var guild:Guild = client.getGuild(guildID);
				if (guild != null) {
					callback(new GuildEmbed(guild, data));
				} else {
					if (error != null) error(new HTTPException(data, "couldn't find guild in storage", 0));
				}
			}
		}, error);
	}
	
	public function modifyGuildEmbed(guildID:String, data:Dynamic, ?callback:GuildEmbed-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("patch", 'guilds/$guildID/embed', data, function (resp:HTTPResponse) {
			if (callback != null) {
				var data:Dynamic = resp.getJson();
				var guild:Guild = client.getGuild(guildID);
				if (guild != null) {
					callback(new GuildEmbed(guild, data));
				} else {
					if (error != null) error(new HTTPException(data, "couldn't find guild in storage", 0));
				}
			}
		}, error);
	}
	
	public function getInvite(inviteCode:String, ?callback:Invite-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'invites/$inviteCode', null, function (resp:HTTPResponse) {
			if (callback != null) callback(new Invite(resp.getJson()));
		}, error);
	}
	
	public function deleteInvite(inviteCode:String, ?callback:Invite-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("delete", 'invites/$inviteCode', null, function (resp:HTTPResponse) {
			if (callback != null) callback(new Invite(resp.getJson()));
		}, error);
	}
	
	public function acceptInvite(inviteCode:String, ?callback:Invite-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("post", 'invites/$inviteCode', null, function (resp:HTTPResponse) {
			if (callback != null) callback(new Invite(resp.getJson()));
		}, error);
	}
	
	public function getCurrentUser(?callback:User-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'users/@me', null, function (resp:HTTPResponse) {
			if (callback != null) {
				if (client.me == null) client.me = new User(resp.getJson());
				callback(client.me);
			}
		}, error);
	}
	
	public function getUser(userID:String, ?callback:User-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'users/$userID', null, function (resp:HTTPResponse) {
			if (callback != null) callback(new User(resp.getJson()));
		}, error);
	}
	
	public function modifyCurrentUser(data:Dynamic, ?callback:User-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("patch", 'users/@me', data, function (resp:HTTPResponse) {
			var data:Dynamic = resp.getJson();
			if (client.me == null) {
				client.me = new User(data);
			} else {
				client.me.parseData(data);
			}
			if (callback != null) callback(client.me);
		}, error);
	}
	
	public function getCurrentUserGuilds(?callback:Array<UserGuild>-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'users/@me/guilds', null, function (resp:HTTPResponse) {
			var data:Array<Dynamic> = resp.getJson();
			var userGuilds:Array<UserGuild> = new Array<UserGuild>();
			for (rawUserGuild in data) {
				userGuilds.push(new UserGuild(rawUserGuild));
			}
			if (callback != null) callback(userGuilds);
		}, error);
	}
	
	public function leaveGuild(guildID:String, ?callback:Void-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("delete", 'users/@me/guilds/$guildID', null, function (resp:HTTPResponse) {
			if (callback != null) callback();
		}, error);
	}
	
	public function getUserDMs(?callback:Map<String, PrivateChannel>-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'users/@me/channels', null, function (resp:HTTPResponse) {
			var data:Array<Dynamic> = resp.getJson();
			for (rawPrivateChannel in data) {
				if (!client.privateChannels.exists(BaseChannel.getID(rawPrivateChannel))) {
					var channel:PrivateChannel = new PrivateChannel(rawPrivateChannel);
					client.privateChannels.set(channel.id, channel);
				}
			}
			if (callback != null) callback(client.privateChannels);
		}, error);
	}
	
	public function createDM(data:Dynamic, ?callback:PrivateChannel-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("post", 'users/@me/channels', data, function (resp:HTTPResponse) {
			var data:Dynamic = resp.getJson();
			var channel:PrivateChannel = client.privateChannels.get(BaseChannel.getID(data));
			if (channel == null) {
				channel = new PrivateChannel(data);
				client.privateChannels.set(channel.id, channel);
			}
			if (callback != null) callback(channel);
		}, error);
	}
	
	public function getUsersConnections(?callback:Array<UserConnection>-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'users/@me/connections', null, function(resp:HTTPResponse) {
			if (callback != null) {
				var data:Array<Dynamic> = resp.getJson();
				var connections:Array<UserConnection> = new Array<UserConnection>();
				for (rawConnection in data) {
					connections.push(new UserConnection(rawConnection));
				}
				callback(connections);
			}
		}, error);
	}
	
	public function listVoiceRegions(?callback:Array<VoiceRegion>-> Void, ?error:HTTPException->Void):Future
	{
		return callAPI("get", 'voice/regions', null, function (resp:HTTPResponse) {
			if (callback != null) {
				var data:Array<Dynamic> = resp.getJson();
				var regions:Array<VoiceRegion> = new Array<VoiceRegion>();
				for (rawRegion in data) {
					regions.push(new VoiceRegion(rawRegion));
				}
				callback(regions);
			}
		}, error);
	}
}