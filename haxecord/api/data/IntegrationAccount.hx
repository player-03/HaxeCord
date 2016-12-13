package haxecord.api.data;

typedef IntegrationAccountPackage = {
	var id:String;
	var name:String;
}

/**
 * ...
 * @author Billyoyo
 */
class IntegrationAccount
{
	public var id(default, null):String;
	public var name(default, null):String;
	
	public function new(data:Dynamic) 
	{
		parseData(data);
	}
	
	private function parseData(data:IntegrationAccountPackage)
	{
		this.id = data.id;
		this.name = data.name;
	}
	
}