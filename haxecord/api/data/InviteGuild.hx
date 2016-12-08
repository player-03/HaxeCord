package haxecord.api.data;

typedef InviteGuildPackage = {
	var id:String,
	var name:String,
	var splash:String,
	var icon:String
}

/**
 * ...
 * @author Billyoyo
 */
class InviteGuild
{
	public var id(default, null):String;
	public var name(default, null):String;
	public var splashHash(default, null):String;
	public var iconHash(default, null):String;

	public function new(data:Dynamic) 
	{
		parseData(data);
	}
	
	private function parseData(data:InviteGuildPackage) {
		this.id = data.id;
		this.name = data.name;
		this.splashHash = data.splash;
		this.iconHash = data.icon;
	}
	
}