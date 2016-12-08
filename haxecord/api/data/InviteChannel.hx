package haxecord.api.data;
import haxecord.api.data.BaseChannel.ChannelType;

typedef InviteChannelPackage = {
	var id:String,
	var name:String,
	var type:String
}

/**
 * ...
 * @author Billyoyo
 */
class InviteChannel
{
	public var id(default, null):String;
	public var name(default, null):String;
	public var channelType(default, null):ChannelType;

	public function new(data:Dynamic) 
	{
		parseData(data);
	}
	
	public function parseData(data:InviteChannelPackage)
	{
		this.id = data.id;
		this.name = data.name;
		if (data.type == "voice") {
			this.channelType = ChannelType.VOICE;
		} else {
			this.channelType = ChannelType.TEXT;
		}
	}
	
}