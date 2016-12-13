package haxecord.api.data;

typedef InvitePackage = {
	var code:String;
	var guild:Dynamic;
	var channel:Dynamic;
	@:optional var metadata:Dynamic;
}

/**
 * ...
 * @author Billyoyo
 */
class Invite
{
	public var code(default, null):String;
	public var guild(default, null):InviteGuild;
	public var channel(default, null):InviteChannel;
	public var metadata(default, null):InviteMetadata = null;

	public function new(data:Dynamic) 
	{
		parseData(data);
	}
	
	private function parseData(data:InvitePackage)
	{
		this.code = data.code;
		this.guild = new InviteGuild(data.guild);
		this.channel = new InviteChannel(data.channel);
		if (data.metadata != null) this.metadata = new InviteMetadata(data.metadata);
	}
	
}