package haxecord.api.data;

typedef VoiceStatePackage = {
	@:optional var guild_id:String;
	var channel_id:String;
	var user_id:String;
	var session_id:String;
	var deaf:Bool;
	var mute:Bool;
	var self_deaf:Bool;
	var self_mute:Bool;
	var suppress:Bool;
}

/**
 * ...
 * @author Billyoyo
 */
class VoiceState
{
	public var guild(default, null):Guild;
	public var channel(default, null):Channel;
	public var member(default, null):Member;
	public var sessionID(default, null):String;
	public var deaf(default, null):Bool;
	public var mute(default, null):Bool;
	public var selfDeaf(default, null):Bool;
	public var selfMute(default, null):Bool;
	public var supress(default, null):Bool;

	public function new(guild:Guild, data:Dynamic) 
	{
		this.guild = guild;
	}
	
	private function parseData(data:VoiceStatePackage)
	{
		for (channel in guild.channels)
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
		this.supress = data.suppress;
		
	}
	
}