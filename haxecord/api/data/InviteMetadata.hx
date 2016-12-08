package haxecord.api.data;

typedef InviteMetadataPackage = {
	inviter:Dynamic,
	uses:Int,
	max_uses:Int,
	max_age:Int,
	temporary:Bool,
	created_at:String,
	revoked:Bool
}

/**
 * ...
 * @author Billyoyo
 */
class InviteMetadata
{
	public var inviter(default, null):User;
	public var uses(default, null):Int;
	public var max_uses(default, null):Int;
	public var max_age(default, null):Int;
	public var temporary(default, null):Bool;
	public var createdAt(default, null):String; // TODO: convert to datetime
	public var revoked(default, null):Bool;

	public function new(data:Dynamic) 
	{
		parseData(data);
	}
	
	private function parseData(data:InviteMetadataPackage)
	{
		this.inviter = new User(data.inviter);
		this.uses = data.uses;
		this.max_uses = data.max_uses;
		this.max_age = data.max_age;
		this.temporary = data.temporary;
		this.createdAt = data.created_at; // TODO: parse datetime
		this.revoked = data.revoked;
	}
	
}