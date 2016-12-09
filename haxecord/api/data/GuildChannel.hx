package haxecord.api.data;

typedef GuildChannelPackage = {
	var id:String;
	var guild_id:String;
}

/**
 * ...
 * @author Billyoyo
 * This data object is purely for internal usage.
 */
class GuildChannel extends BaseChannel
{
	public var guildID(default, null):String;

	public function new(data) 
	{
		parseData(data);
	}
	
	private function parseData(data:GuildChannelPackage)
	{
		this.id = data.id;
		this.guildID = data.guild_id;
	}
	
	
}