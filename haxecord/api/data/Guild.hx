package haxecord.api.data;
import haxecord.utils.DateTime;


typedef UnavailableGuild = {
	var id:String;
	var unavailable:Bool;
}

typedef GuildPackage = {
	var id:String;
	var name:String;
	var icon:String;
	var splash:String;
	var owner_id:String;
	var region:String;
	var afk_channel_id:String;
	var afk_timeout:Int;
	var embed_enabled:Bool;
	var embed_channel_id:String;
	var verification_level:Int;
	var default_message_notifications:Int;
	var roles:Array<Dynamic>;
	var emojis:Array<Dynamic>;
	var features:Array<String>;
	var mfa_level:Int;
	@:optional var joined_at:String;
	@:optional var large:Bool;
	@:optional var unavailable:Bool;
	@:optional var member_count:Int;
	@:optional var voice_states:Array<Dynamic>;
	@:optional var members:Array<Dynamic>;
	@:optional var channels:Array<Dynamic>;
	@:optional var presences:Array<Dynamic>;
}

typedef GuildUnavilableCheck = {
	@:optional var unavailable:Bool;
}

typedef GuildEmojiUpdate = {
	var emojis:Array<Dynamic>;
}

typedef GuildMemberUpdateHelper = {
	var user:Dynamic;
}

typedef GuildLoadMembers = {
	var members:Array<Dynamic>;
}

typedef GuildRoleCreate = {
	var role:Dynamic;
}

typedef VoiceServerUpdatePackage = {
	var token:String;
	var endpoint:String;
}

typedef PresenceUpdatePackage = {
	@:optional var user:Dynamic;
	@:optional var roles:Array<String>;
	@:optional var game:Dynamic;
	@:optional var status:String;
}

/**
 * ...
 * @author Billyoyo
 */
class Guild
{
	public static function guildUnavailable(data:GuildUnavilableCheck){
		return data.unavailable;
	}
	
	public var unavailable(default, null):Bool;
	public var id(default, null):String;
	public var name(default, null):String;
	public var iconHash(default, null):String;
	public var splashHash(default, null):String;
	
	private var ownerID:String;
	public var owner(get, null):Member;
	private var _owner:Member = null;
	function get_owner() {
		if (_owner == null) {
			for (member in members) {
				if (member.id == ownerID)
				{
					_owner = member;
				}
			}
		}
		return _owner;
	}
	
	public var region(default, null):String;
	
	private var afkChannelID:String;
	public var afkChannel(get, null):Channel;
	private var _afkChannel:Channel = null;
	function get_afkChannel() {
		if (_afkChannel == null) {
			for (channel in channels) {
				if (channel.id == afkChannelID) {
					_afkChannel = channel;
					break;
				}
			}
		}
		return _afkChannel;
	}
	
	public var afkTimeout(default, null):Int;
	public var embedEnabled(default, null):Bool;
	
	private var embedChannelID:String;
	public var embedChannel(get, null):Channel;
	private var _embedChannel:Channel = null;
	function get_embedChannel() {
		if (_embedChannel == null) {
			for (channel in channels) {
				if (channel.id == embedChannelID) {
					_embedChannel = channel;
					break;
				}
			}
		}
		return _embedChannel;
	}
	
	public var verificationLevel(default, null):Int;
	public var defaultMessageNotifs(default, null):Int;
	public var roles(default, null):Array<Role>; 
	public var emojis(default, null):Array<Emoji>;
	public var features(default, null):Array<String>;
	public var mfaLevel(default, null):Int;
	public var joinedAt(default, null):DateTime;
	public var large(default, null):Bool;
	public var memberCount(default, null):Int;
	public var members(default, null):Array<Member>;
	public var channels(default, null):Array<Channel>;
	public var voiceChannels(default, null):Array<VoiceChannel>;
	public var voiceStates(default, null):Array<VoiceState>;
	
	public var voiceEndpoint(default, null):String;
	public var voiceToken(default, null):String;

	public function new(data:Dynamic) 
	{
		parseData(data);
	}
	
	public function parseData(rawData:Dynamic)
	{
		var unvailableCheck:UnavailableGuild = rawData;
		if (unvailableCheck.unavailable != null && unvailableCheck.unavailable) {
			this.id = unvailableCheck.id;
			this.unavailable = true;
		} else {
			var data:GuildPackage = rawData;
			this.id = data.id;
			this.name = data.name;
			this.iconHash = data.icon;
			this.splashHash = data.splash;
			this.ownerID = data.owner_id;
			this.region = data.region;
			this.afkChannelID = data.afk_channel_id;
			this.afkTimeout = data.afk_timeout;
			this.embedEnabled = data.embed_enabled;
			this.embedChannelID = data.embed_channel_id;
			this.verificationLevel = data.verification_level;
			this.defaultMessageNotifs = data.default_message_notifications;
			
			this.roles = new Array<Role>();
			if (data.roles != null) {
				for (rawRole in data.roles) {
					this.roles.push(new Role(rawRole));
				}
			}
			
			this.emojis = new Array<Emoji>();
			if (data.emojis != null) {
				for (rawEmoji in data.emojis) {
					this.emojis.push(new Emoji(rawEmoji));
				}
			}
			
			this.features = data.features;
			this.mfaLevel = data.mfa_level;
			this.memberCount = data.member_count;
			
			if (data.joined_at != null) { // initial package
				this.joinedAt = DateTime.fromString(data.joined_at);
				this.large = data.large;
				
				this.members = new Array<Member>();
				if (data.members != null) {
					for (rawMember in data.members) {
						this.members.push(new Member(this, rawMember));
					}
				}
				
				this.channels = new Array<Channel>();
				if (data.channels != null) {
					for (rawChannel in data.channels) {
						if (BaseChannel.isVoiceChannel(rawChannel)) {
							this.voiceChannels.push(new VoiceChannel(this, rawChannel));
						} else {
							this.channels.push(new Channel(this, rawChannel));
						}
					}
				}
				
				this.voiceStates = new Array<VoiceState>();
				if (data.voice_states != null) {
					for (rawVoiceState in data.voice_states)
					{
						this.voiceStates.push(new VoiceState(this, rawVoiceState));
					}
				}
				
				if (data.presences != null) {
					for (presenceUpdate in data.presences) {
						updatePresence(presenceUpdate);
					}
				}
			}
		}
	}
	
	public function updatePresence(data:PresenceUpdatePackage):Member
	{
		if (data.user != null) {
			var userID:String = BaseChannel.getID(data.user);
			for (member in members)
			{
				if (member.id == userID) {
					if (data.game != null) member.updateGame(data.game);
					if (data.status != null) member.updateStatus(User.getStatus(data.status));
					return member;
				}
			}
		}
		return null;
	}
	
	public function updateVoiceState(data:Dynamic):VoiceState
	{
		var voiceState:VoiceState = getVoiceState(User.getUserID(data));
		if (voiceState != null) {
			voiceState.updateVoiceState(data);
		} else {
			voiceState = new VoiceState(this, data);
			voiceStates.push(voiceState);
		}
		return voiceState;
	}
	
	public function updateVoiceServer(data:VoiceServerUpdatePackage) {
		this.voiceEndpoint = data.endpoint;
		this.voiceToken = data.token;
	}
	
	public function updateEmojis(data:GuildEmojiUpdate) {
		this.emojis = new Array<Emoji>();
		for (rawEmoji in data.emojis) {
			this.emojis.push(new Emoji(rawEmoji));
		}
	}
	
	public function updateMember(data:Dynamic):Member {
		var helper:GuildMemberUpdateHelper = data;
		var member:Member = getMember(BaseChannel.getID(helper.user));
		if (member != null) {
			member.updateMemberData(data);
		}
		return member;
	}
	
	public function loadMembersChunk(data:GuildLoadMembers) {
		for (rawMember in data.members) {
			members.push(new Member(this, rawMember));
		}
	}
	
	public function createRole(data:GuildRoleCreate):Role {
		var role:Role = new Role(data.role);
		roles.push(role);
		return role;
	}
	
	public function updateRole(data:GuildRoleCreate):Role {
		var role:Role = getRole(BaseChannel.getID(data.role));
		if (role != null) {
			role.parseData(data.role);
		}
		return role;
	}
	
	
	public function getChannel(id:String):Channel
	{
		for (channel in channels) {
			if (channel.id == id) return channel;
		}
		return null;
	}
	
	public function getVoiceChannel(id:String):VoiceChannel
	{
		for (voiceChannel in voiceChannels) {
			if (voiceChannel.id == id) return voiceChannel;
		}
		return null;
	}
	
	public function getMember(id:String):Member
	{
		for (member in members) {
			if (member.id == id) return member;
		}
		return null;
	}
	
	public function getRole(id:String):Role
	{
		for (role in roles) {
			if (role.id == id) return role;
		}
		return null;
	}
	
	public function getVoiceState(userid:String):VoiceState
	{
		for (vc in voiceStates) {
			if (vc.member.id == userid) return vc;
		}
		return null;
	}
	
	public function hasChannel(channelID:String):Bool
	{
		for (channel in channels) {
			if (channel.id == channelID) return true;
		}
		return false;
	}
	
}