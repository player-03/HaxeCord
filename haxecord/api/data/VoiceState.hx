package haxecord.api.data;

typedef VoiceStatePackage = {
	@:optional var guild_id:String;
	@:optional var channel_id:String;
	@:optional var user_id:String;
	@:optional var session_id:String;
	@:optional var deaf:Bool;
	@:optional var mute:Bool;
	@:optional var self_deaf:Bool;
	@:optional var self_mute:Bool;
	@:optional var suppress:Bool;
}

/**
 * ...
 * @author Billyoyo
 */
class VoiceState
{
	public var guild(default, null):Guild;
	public var channel(default, null):VoiceChannel;
	public var member(default, null):Member;
	public var sessionID(default, null):String;
	public var deaf(default, null):Bool;
	public var mute(default, null):Bool;
	public var selfDeaf(default, null):Bool;
	public var selfMute(default, null):Bool;
	public var suppress(default, null):Bool;

	public function new(guild:Guild, data:Dynamic) 
	{
		this.guild = guild;
	}
	
	private function parseData(data:VoiceStatePackage)
	{
		for (channel in guild.voiceChannels)
		{
			if (channel.id == data.channel_id) {
				this.channel = channel;
				break;
			}
		}
		
		for (user in guild.members)
		{
			if (user.id == data.user_id)
			{
				this.member = user;
				break;
			}
		}
		
		this.sessionID = data.session_id;
		this.deaf = data.deaf;
		this.mute = data.mute;
		this.selfDeaf = data.self_deaf;
		this.selfMute = data.self_mute;
		this.suppress = data.suppress;
		
	}
	
	public function updateVoiceState(data:VoiceStatePackage)
	{
		if (data.channel_id != null)
		{
			for (channel in guild.voiceChannels)
			{
				if (channel.id == data.channel_id) {
					this.channel = channel;
					break;
				}
			}
		}
		
		if (data.user_id != null) {
			for (user in guild.members)
			{
				if (user.id == data.user_id)
				{
					this.member = user;
					break;
				}
			}
		}
		
		if (data.session_id != null) this.sessionID = data.session_id;
		if (data.deaf != null) this.deaf = data.deaf;
		if (data.mute != null) this.mute = data.mute;
		if (data.self_deaf != null) this.selfDeaf = data.self_deaf;
		if (data.self_mute != null) this.selfMute = data.self_mute;
		if (data.suppress != null) this.suppress = data.suppress;
		
	}
	
}