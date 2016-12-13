package haxecord.api.data;

typedef UserGuildPackage = {
	var id:String;
	var name:String;
	var icon:String;
	var owner:Bool;
	var permissions:Int;
}

/**
 * ...
 * @author Billyoyo
 */
class UserGuild
{
	public var id(default, null):String;
	public var name(default, null):String;
	public var icon(default, null):String;
	public var owner(default, null):Bool;
	public var permissions(default, null):Permissions;

	public function new(data:Dynamic) 
	{
		parseData(data);
	}
	
	public function parseData(data:UserGuildPackage) {
		this.id = data.id;
		this.name = data.name;
		this.icon = data.icon;
		this.owner = data.owner;
		this.permissions = new Permissions(data.permissions);
	}
	
}