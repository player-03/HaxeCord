package haxecord.api;
import haxecord.api.Client;
import haxecord.api.data.Message;

/**
 * ...
 * @author Billyoyo
 */
class APIEventListener
{
	public var client:Client;

	public function new(client:Client) 
	{
		this.client = client;
	}
	
	public function onMessage(message:Message):Void {}
	
}