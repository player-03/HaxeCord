package haxecord.api.data;

typedef VoiceRegionPackage = {
	var id:String,
	var name:String,
	var sample_hostname:String,
	var sample_port:Int,
	var vip:Bool,
	var optimal:Bool,
	var deprecated:Bool,
	var custom:Bool
}

/**
 * ...
 * @author Billyoyo
 */
class VoiceRegion
{
	public var id(default, null):String;
	public var name(default, null):String;
	public var sampleHostname(default, null):String;
	public var samplePort(default, null):Int;
	public var vip(default, null):Bool;
	public var optimal(default, null):Bool;
	public var deprecated(default, null):Bool;
	public var custom(default, null):Bool;

	public function new(data:Dynamic) 
	{
		parseData(data);
	}
	
	private function parseData(data:VoiceRegionPackage)
	{
		this.id = data.id;
		this.name = data.name;
		this.sampleHostname = data.sample_hostname;
		this.samplePort = data.sample_port;
		this.vip = data.vip;
		this.optimal = data.optimal;
		this.deprecated = data.deprecated;
		this.custom = data.custom;
	}
}