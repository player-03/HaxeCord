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
			client.sendMessage(message.channel.id, "pong!").send();
		}
	}

	public static function main() 
	{
		var client:Client = new Client();
		
		client.addListener(new BotExample(client));
		
		client.run("token");
	}
}