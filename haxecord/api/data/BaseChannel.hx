package haxecord.api.data;

enum ChannelType {
	TEXT;
	VOICE;
	PRIVATE;
}

typedef PrivateCheck = {
	var is_private:Bool;
}

typedef VoiceChannelCheck = {
	var type:String;
}

typedef GuildGet = {
	var guild_id:String;
}

typedef ChannelIDGet = {
	var channel_id:String;
}

typedef IDGet = {
	var id:String;
}

/**
 * ...
 * @author Billyoyo
 */
class BaseChannel
{
	public static function isPrivateChannel(data:PrivateCheck):Bool {
		return data.is_private;
	}
	
	public static function isVoiceChannel(data:VoiceChannelCheck):Bool {
		return data.type == "voice";
	}
	
	public static function getChannelID(data:ChannelIDGet) {
		return data.channel_id;
	}
	
	public static function getGuildID(data:GuildGet):String {
		return data.guild_id;
	}
	
	public static function getID(data:IDGet):String {
		return data.id;
	}
	
	
	
	public var id(default, null):String;
	
	public var channelType(default, null):ChannelType;
	
}