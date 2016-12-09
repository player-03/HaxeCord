package haxecord.api.data;

typedef ChannelPackage = {
	var id:String;
	var guild_id:String;
	var name:String;
	var type:String;
	var position:Int;
	var isPrivate:Bool;
	var premission_overwrites:Array<Dynamic>;
	var topic:String;
	var last_message_id:String;
}



/**
 * ...
 * @author Billyoyo
 */
class Channel extends BaseChannel
{
	public var guild(default, null):Guild;
	public var name(default, null):String;
	public var position(default, null):Int;
	
	public var permissionOverwrites(default, null):Array<PermissionOverwrite>;
	public var topic(default, null):String;
	public var lastMessageID(default, null):String;
	
	public function new(guild:Guild, data:Dynamic) 
	{
		this.channelType = BaseChannel.ChannelType.TEXT;
		this.guild = guild;
		parseData(data);
	}
	
	private function parseData(data:ChannelPackage)
	{
		this.id = data.id;
		this.name = data.name;
		this.position = data.position;
		
		this.permissionOverwrites = new Array<PermissionOverwrite>();
		if (data.premission_overwrites != null) {
			for (rawOverwrite in data.premission_overwrites) {
				this.permissionOverwrites.push(new PermissionOverwrite(rawOverwrite));
			}
		}
		
		this.topic = data.topic;
		this.lastMessageID = data.last_message_id;
	}
	
	public function updateData(data:ChannelPackage)
	{
		if (data.id != null) this.id = data.id;
		if (data.name != null) this.name = data.name;
		if (data.position != null) this.position = data.position;
		
		if (data.premission_overwrites != null) {
			this.permissionOverwrites = new Array<PermissionOverwrite>();
			for (rawOverwrite in data.premission_overwrites) {
				this.permissionOverwrites.push(new PermissionOverwrite(rawOverwrite));
			}
		}
		
		if (data.topic != null) this.topic = data.topic;
		if (data.last_message_id != null) this.lastMessageID = data.last_message_id;
	}
	
}