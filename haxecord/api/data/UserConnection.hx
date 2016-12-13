package haxecord.api.data;
import haxecord.api.data.Integration.IntegrationPackage;

typedef UserConnectionPackage = {
	var id:String;
	var name:String;
	var type:String;
	var revoked:Bool;
	var integrations:Array<Dynamic>;
}

/**
 * ...
 * @author Billyoyo
 */
class UserConnection
{
	public var id(default, null):String;
	public var name(default, null):String;
	public var type(default, null):String;
	public var revoked(default, null):Bool;
	public var integrations(default, null):Array<Integration>;

	public function new(data:Dynamic) 
	{
		parseData(data);
	}
	
	private function parseData(data:UserConnectionPackage)
	{
		this.id = data.id;
		this.name = data.name;
		this.type = data.type;
		this.revoked = data.revoked;
		this.integrations = new Array<Integration>();
		for (rawIntegration in data.integrations) {
			this.integrations.push(new Integration(rawIntegration));
		}
	}
}