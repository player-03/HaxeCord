package haxecord.api.data;

typedef ReactionPackage = {
	var count:Int;
	var me:Bool;
	var emoji:Dynamic;
}

/**
 * ...
 * @author Billyoyo
 */
class Reaction
{
	public var count(default, null):Int;
	public var me(default, null):Bool;
	public var emoji(default, null):BaseEmoji;
	
	public function new(data:Dynamic) 
	{
		parseData(data);
	}
	
	private function parseData(data:ReactionPackage)
	{
		this.count = data.count;
		this.me = data.me;
		this.emoji = new ReactionEmoji(data.emoji);
	}
	
}