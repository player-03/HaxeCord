package haxecord.api.data;

typedef VoiceChannelPackage = {
	var id:String;
	var guild_id:String;
	var name:String;
	var type:String;
	var position:Int;
	var isPrivate:Bool;
	var permission_overwrites:Array<Dynamic>;
	var bitrate:Int;
	var user_limit:Int;
}

/**
 * ...
 * @author Billyoyo
 */
class VoiceChannel extends BaseChannel
{
	public var guild(default, null):Guild;
	public var name(default, null):String;
	public var position(default, null):Int;
	
	public var permissionOverwrites(default, null):Array<PermissionOverwrite>;
	public var bitrate:Int;
	public var userLimit:Int;

	public function new(guild:Guild, data:Dynamic) 
	{
		this.channelType = BaseChannel.ChannelType.VOICE;
		this.guild = guild;
		parseData(data);
	}
	
	private function parseData(data:VoiceChannelPackage)
	{
		this.id = data.id;
		this.name = data.name;
		this.position = data.position;
		
		this.permissionOverwrites = new Array<PermissionOverwrite>();
		for (rawOverwrite in data.permission_overwrites) {
			this.permissionOverwrites.push(new PermissionOverwrite(rawOverwrite));
		}
		
		this.bitrate = data.bitrate;
		this.userLimit = data.user_limit;
	}
	
	public function updateData(data:VoiceChannelPackage)
	{
		if (data.id != null) this.id = data.id;
		if (data.name != null) this.name = data.name;
		if (data.position != null) this.position = data.position;
		
		if (data.permission_overwrites != null) {
			this.permissionOverwrites = new Array<PermissionOverwrite>();
			for (rawOverwrite in data.permission_overwrites) {
				this.permissionOverwrites.push(new PermissionOverwrite(rawOverwrite));
			}
		}
		
		if (data.bitrate != null) this.bitrate = data.bitrate;
		if (data.user_limit != null) this.userLimit = data.user_limit;
	}
	
}