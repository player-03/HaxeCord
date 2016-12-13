package haxecord.http;
import haxe.io.Bytes;
import haxe.Json;

/**
 * ...
 * @author Billyoyo
 */
class HTTPResponse
{
	public var status:Int;
	public var content:Bytes;
	public var contentLength:Int;
	public var headers:Map<String, String>;
	public var redirects:Array<String>;

	public function new(status:Int, redirects:Array<String>, content:Bytes, contentLength:Int, headers:Map<String, String>) 
	{
		this.status = status;
		this.redirects = redirects;
		this.content = content;
		this.contentLength = contentLength;
		this.headers = headers;
	}
	
	public function getJson():Dynamic
	{
		return Json.parse(content.toString());
	}
	
}