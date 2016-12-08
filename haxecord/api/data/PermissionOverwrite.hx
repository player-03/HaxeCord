package haxecord.api.data;

typedef OverwritePackage = {
	var id:String;
	var type:String;
	var allow:Int;
	var deny:Int;
}

enum PermissionType {
	ROLE;
	MEMBER;
}

/**
 * ...
 * @author Billyoyo
 */
class PermissionOverwrite
{
	public var id(default, null):String;
	public var type(default, null):PermissionType;
	public var allow(default, null):Int;
	public var deny(default, null):Int;

	public function new(data:Dynamic) 
	{
		parseData(data);
	}
	
	private function parseData(data:OverwritePackage)
	{
		this.id = data.id;
		if (data.type == "role") {
			this.type = PermissionType.ROLE;
		} else {
			this.type = PermissionType.MEMBER;
		}
		this.allow = data.allow;
		this.deny = data.deny;
	}
	
}