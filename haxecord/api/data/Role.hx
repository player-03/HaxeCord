package haxecord.api.data;

typedef RolePackage = {
	var id:String;
	var name:String;
	var color:Int;
	var hoist:Bool;
	var position:Int;
	var permissions:Int;
	var managed:Bool;
	var mentionable:Bool;
}

/**
 * ...
 * @author Billyoyo
 */
class Role
{
	public var id(default, null):String;
	public var name(default, null):String;
	public var colour(default, null):Colour;
	public var hoist(default, null):Bool;
	public var position(default, null):Int;
	public var permissions(default, null):Permissions;
	public var managed(default, null):Bool;
	public var mentionable(default, null):Bool;

	public function new(data:Dynamic) 
	{
		parseData(data);
	}
	
	private function parseData(data:RolePackage)
	{
		this.id = data.id;
		this.name = data.name;
		this.colour = new Colour(data.color);
		this.hoist = data.hoist;
		this.position = data.position;
		this.permissions = new Permissions(data.permissions);
		this.managed = data.managed;
		this.mentionable = data.mentionable;
	}
	
}