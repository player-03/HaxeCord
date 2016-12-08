package haxecord.api.data;

typedef UserPackage = {
	var id:String;
	var username:String;
	var discriminator:String;
	var avatar:String;
	var bot:Bool;
	var mfa_enabled:Bool;
	var verified:Bool;
	@:optional var email:String;
}

/**
 * ...
 * @author Billyoyo
 */
class User
{
	public var id(default, null):String;
	public var username(default, null):String;
	public var discriminator(default, null):String;
	public var avatarHash(default, null):String;
	public var bot(default, null):Bool;
	public var mfa_enabled(default, null):Bool;
	public var verified(default, null):Bool;
	public var email(default, null):String;

	public function new(data:Dynamic) 
	{
		parseData(data);
	}
	
	private function parseData(data:UserPackage):Void
	{
		this.id = data.id;
		this.username = data.username;
		this.discriminator = data.discriminator;
		this.avatarHash = data.avatar;
		this.bot = data.bot;
		this.mfa_enabled = data.mfa_enabled;
		this.email = data.email;
	}
	
}