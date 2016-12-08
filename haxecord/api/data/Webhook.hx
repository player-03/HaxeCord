package haxecord.api.data;

typedef WebhookPackage = {
	var id:String,
	@:optional var guild_id:String,
	var channel_id:String,
	@:optional var user:Dynamic,
	@:optional var name:String,
	@:optional var avatar:String,
	@:optional var token:String
}

/**
 * ...
 * @author Billyoyo
 */
class Webhook
{
	public var id(default, null):String;
	public var guildID(default, null):String;
	public var channelID(default, null):String;
	public var user(default, null):User;
	public var name(default, null):String;
	public var avatarHash(default, null):String;
	public var token(default, null):String;
	
	public function new(data:Dynamic) 
	{
		parseData(data);
	}
	
	private function parseData(data:WebhookPackage)
	{
		this.id = data.id;
		this.guildID = data.guild_id;
		this.channelID = data.channel_id;
		if (data.user != null) this.user = new User(data.user);
		this.name = data.name;
		this.avatarHash = data.avatar;
		this.token = data.token;
	}
	
}