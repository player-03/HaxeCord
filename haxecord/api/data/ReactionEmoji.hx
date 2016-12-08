package haxecord.api.data;

typedef ReactionEmojiPackage = {
	var id:String;
	var name:String;
}

/**
 * ...
 * @author Billyoyo
 */
class ReactionEmoji extends BaseEmoji
{
	
	public function new(data:Dynamic) 
	{
		this.isFilled = false;
		parseData(data);
	}
	
	private function parseData(data:ReactionEmojiPackage)
	{
		this.id = data.id;
		this.name = data.name;
	}
}