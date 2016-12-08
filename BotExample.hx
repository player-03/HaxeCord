package haxecord;
import haxecord.api.APIEventListener;
import haxecord.api.Client;
import haxecord.api.data.Message;

/**
 * ...
 * @author Billyoyo
 */
class BotExample extends APIEventListener
{
	
	override public function onMessage(message:Message):Void 
	{
		if (message.content == "!ping") {
			client.sendMessage("247794820544724992", "pong!").send();
		}
	}

	public static function main() 
	{
		var client:Client = new Client();
		
		client.addListener(new BotExample(client));
		
		client.run("token");
	}
}