package haxecord.api.data;

typedef EmojiPackage = {
	var id:String;
	var name:String;
	var roles:Array<String>;
	var require_colons:Bool;
	var managed:Bool;
}

/**
 * ...
 * @author Billyoyo
 */
class Emoji extends BaseEmoji
{
	public var roleIDs(default, null):Array<String>;
	public var requireColons(default, null):Bool;
	public var managed(default, null):Bool;

	public function new(data:Dynamic) 
	{
		this.isFilled = true;
		parseData(data);
	}
	
	private function parseData(data:EmojiPackage)
	{
		this.id = data.id;
		this.name = data.name;
		this.roleIDs = data.roles;
		this.requireColons = data.require_colons;
		this.managed = data.managed;
	}
	
}