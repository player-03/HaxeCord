package haxecord.api.data;

typedef AttachmentPackage = {
	var id:String;
	var filename:String;
	var size:Int;
	var url:String;
	var proxy_url:String;
	@:optional var height:Int;
	@:optional var width:Int;
}

/**
 * ...
 * @author Billyoyo
 */
class MessageAttachment
{
	public var id(default, null):String;
	public var filename(default, null):String;
	public var size(default, null):Int;
	public var url(default, null):String;
	public var proxyUrl(default, null):String;
	
	public var height(default, null):Int;
	public var width(default, null):Int;

	public function new(data:Dynamic) 
	{
		parseData(data);
	}
	
	private function parseData(data:AttachmentPackage)
	{
		this.id = data.id;
		this.filename = data.filename;
		this.size = data.size;
		this.url = data.url;
		this.proxyUrl = data.proxy_url;
		this.height = data.height;
		this.width = data.width;
	}
}