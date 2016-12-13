package haxecord.api.data;

typedef IntegrationPackage = {
	var id:String;
	var name:String;
	var type:String;
	var enabled:Bool;
	var syncing:Bool;
	var role_id:String;
	var expire_behavior:Int;
	var expire_grace_period:Int;
	var user:Dynamic;
	var account:Dynamic;
	var synced_at:String;
}

/**
 * ...
 * @author Billyoyo
 */
class Integration
{
	public var id(default, null):String;
	public var name(default, null):String;
	public var type(default, null):String;
	public var enabled(default, null):Bool;
	public var syncing(default, null):Bool;
	public var roleID(default, null):String;
	public var expireBehavior(default, null):Int;
	public var expireGracePerioud(default, null):Int;
	public var user(default, null):User;
	public var account(default, null):IntegrationAccount;
	public var synced_at(default, null):String; // TODO: convert to timestamp

	public function new(data:Dynamic) 
	{
		parseData(data);
	}
	
	private function parseData(data:IntegrationPackage)
	{
		this.id = data.id;
		this.name = data.name;
		this.type = data.type;
		this.enabled = data.enabled;
		this.syncing = data.syncing;
		this.roleID = data.role_id;
		this.expireBehavior = data.expire_behavior;
		this.expireGracePerioud = data.expire_grace_period;
		this.user = new User(data.user);
		this.account = new IntegrationAccount(data.account);
		this.synced_at = data.synced_at;
	}
	
}