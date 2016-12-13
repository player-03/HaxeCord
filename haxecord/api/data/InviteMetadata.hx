package haxecord.api.data;
import haxecord.utils.DateTime;

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
	public var createdAt(default, null):DateTime;
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
		if (data.created_at != null) this.createdAt = DateTime.fromString(data.created_at);
		this.revoked = data.revoked;
	}
	
}