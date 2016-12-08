package haxecord.api.data;

typedef GuildEmbedPackage = {
	var enabled:Bool,
	var channel_id:String
}

/**
 * ...
 * @author Billyoyo
 */
class GuildEmbed
{
	public var guild:Guild(default, null):Guild;
	public var enabled(default, null):Bool;
	public var channel(default, null):Channel;
	
	public function new(guild:Guild, data:Dynamic) 
	{
		this.guild = guild;
		parseData(data);
	}
	
	private function parseData(data:GuildEmbedPackage)
	{
		this.enabled = data.enabled;
		for (channel in guild.channels) {
			if (channel.id == data.channel_id) {
				this.channel = channel;
				break;
			}
		}
	}
	
}