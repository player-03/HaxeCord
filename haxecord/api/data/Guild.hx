package haxecord.api.data;


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

/**
 * ...
 * @author Billyoyo
 */
class Guild
{
	public var unavailable(default, null):Bool;
	public var id(default, null):String;
	public var name(default, null):String;
	public var iconHash(default, null):String;
	public var splashHash(default, null):String;
	
	public var ownerID(default, null):String;
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
	
	public var afkChannelID(default, null):String;
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
	
	public var embedChannelID(default, null):String;
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
	public var joinedAt(default, null):String; // TODO: convert to datetime
	public var large(default, null):Bool;
	public var memberCount(default, null):Int;
	public var members(default, null):Array<Member>;
	public var channels(default, null):Array<Channel>;
	public var voiceChannels(default, null):Array<VoiceChannel>;
	public var presences(default, null):Array<Dynamic>; // TODO: fill with presence updates
	public var voiceStates(default, null):Array<VoiceState>;

	public function new(data:Dynamic) 
	{
		parseData(data);
	}
	
	private function parseData(rawData:Dynamic)
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
			for (rawRole in data.roles) {
				this.roles.push(new Role(rawRole));
			}
			
			this.emojis = new Array<Emoji>();
			for (rawEmoji in data.emojis) {
				this.emojis.push(new Emoji(rawEmoji));
			}
			
			this.features = data.features;
			this.mfaLevel = data.mfa_level;
			this.memberCount = data.member_count;
			
			if (data.joined_at != null) { // initial package
				this.joinedAt = data.joined_at;
				this.large = data.large;
				
				this.members = new Array<Member>();
				for (rawMember in data.members) {
					this.members.push(new Member(this, rawMember));
				}
				
				this.channels = new Array<Channel>();
				for (rawChannel in data.channels) {
					if (Channel.isVoiceChannel(rawChannel)) {
						this.voiceChannels.push(new VoiceChannel(this, rawChannel));
					} else {
						this.channels.push(new Channel(this, rawChannel));
					}
				}
				
				this.presences = data.presences; // TODO: parse presences
				
				this.voiceStates = new Array<VoiceState>();
				for (rawVoiceState in data.voice_states)
				{
					this.voiceStates.push(new VoiceState(this, rawVoiceState));
				}
			}
		}
	}
	
}