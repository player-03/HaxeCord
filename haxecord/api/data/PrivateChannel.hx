package haxecord.api.data;

typedef PrivateChannelPackage = {
	var id:String;
	var recipient:Dynamic;
	var last_message_id:String;
}

/**
 * ...
 * @author Billyoyo
 */
class PrivateChannel extends BaseChannel
{
	public var user(default, null):User;
	public var lastMessageID(default, null):String;

	public function new(data:Dynamic) 
	{
		this.channelType = BaseChannel.ChannelType.PRIVATE;
		parseData(data);
	}
	
	private function parseData(data:PrivateChannelPackage) {
		this.id = data.id;
		try {
			this.user = new User(data.recipient);
		} catch ( source:Dynamic ) {
			this.user = null;
		}
		this.lastMessageID = data.last_message_id;
	}
	
}