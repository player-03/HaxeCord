package haxecord.http;

/**
 * ...
 * @author Billyoyo
 */
class HTTPException
{
	public var message:String;
	public var source:Dynamic;
	public var status:Int;
	
	public function new(source:Dynamic, message:String, status:Int) 
	{
		this.source = source;
		this.message = message;	
		this.status = status;
	}
	
}