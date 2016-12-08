package haxecord.api.data;

enum ChannelType {
	TEXT;
	VOICE;
	PRIVATE;
}

/**
 * ...
 * @author Billyoyo
 */
class BaseChannel
{
	public var id(default, null):String;
	
	public var channelType(default, null):ChannelType;
	
}