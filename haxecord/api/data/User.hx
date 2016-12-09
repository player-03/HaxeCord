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

typedef ContainingUserPackage = {
	var user:Dynamic;
}

typedef GetUserID = {
	var user_id:String;
}

typedef GamePackage = {
	var name:String;
}

enum UserStatus {
	IDLE;
	ONLINE;
	OFFLINE;
}

/**
 * ...
 * @author Billyoyo
 */
class User
{
	public static function getStatus(status:String):UserStatus
	{
		return switch (status) {
			case "idle": UserStatus.IDLE;
			case "offline": UserStatus.OFFLINE;
			default: UserStatus.ONLINE;
		}
	}
	
	public static function getUserID(data:GetUserID) {
		return data.user_id;
	}
	
	public static function fromData(data:ContainingUserPackage) {
		return new User(data.user);
	}
	
	public var id(default, null):String;
	public var username(default, null):String;
	public var discriminator(default, null):String;
	public var avatarHash(default, null):String;
	public var bot(default, null):Bool;
	public var mfa_enabled(default, null):Bool;
	public var verified(default, null):Bool;
	public var email(default, null):String;
	public var game(default, null):String;
	public var status(default, null):UserStatus;

	public function new(data:Dynamic) 
	{
		parseData(data);
	}
	
	public function parseData(data:UserPackage):Void
	{
		this.id = data.id;
		this.username = data.username;
		this.discriminator = data.discriminator;
		this.avatarHash = data.avatar;
		this.bot = data.bot;
		this.mfa_enabled = data.mfa_enabled;
		this.email = data.email;
	}
	
	public function updateGame(data:GamePackage)
	{
		this.game = data.name;
	}
	
	public function updateStatus(status:UserStatus)
	{
		this.status = status;
	}
	
}