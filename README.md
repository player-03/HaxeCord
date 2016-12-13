# HaxeCord
Discord API for Haxe with neko (it should also work with python, java, macro, cpp, lua and php but these are untested)

##WARNING
This library is very early in development, expect bugs and missing functionality.

## Included packages
  - `async` a very simplistic concurrency package
  - `http` implementation of https://github.com/yupswing/akifox-asynchttp using the `async` package
  - `nekows` websocket library using the `async` package
  - `api` discord api package
  - `utils` miscellaneous helper classes 


## Basic example
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

## TODO
  - Create the `Embed` data class
  - Properly create the `Permissions` and `Colour` data classes
  - Properly test the dispatch events and data class creation
  - Properly test the `APIHTTP.hx` endpoints
  - Document all of the packages, with examples and test cases
  - Create a command framework

