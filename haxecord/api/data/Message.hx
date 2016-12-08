package haxecord.api.data;
import neko.net.ServerLoop;

typedef MessagePackage = {
	var id:String;
	var channel_id:String;
	var author:Dynamic;
	var content:String;
	var timestamp:String;
	var edited_timestamp:String;
	var tts:Bool;
	var mention_everyone:Bool;
	var mentions:Array<Dynamic>;
	var mention_roles:Array<String>;
	var attachments:Array<Dynamic>;
	var embeds:Array<Dynamic>;
	var reactions:Array<Dynamic>;
	@:optional var nonce:String;
	var pinned:Bool;
	@:optional var webhook_id:String;
}

/**
 * ...
 * @author Billyoyo
 */
class Message
{
	public var id(default, null):String;
	
	public var channelID(default, null):String;
	public var channel(default, null):Channel; // TODO: make client find channel
	public var guild(default, null):Guild; // TODO: make client find guild
	
	public var author(default, null):User; // TODO: make client attempt to convert member object
	public var content(default, null):String;
	public var timestamp(default, null):String; // TODO: convert to timestamp
	public var editedTimestamp(default, null):String; // TODO: convert to edited timestamp
	public var tts(default, null):Bool;
	public var mentionEveryone(default, null):Bool;
	public var mentions(default, null):Array<User>; // TODO: make client convert to member objects
	public var mentionRoleIDs(default, null):Array<String>; // TODO: create a mentionRoles array of Role objects
	public var attachments(default, null):Array<MessageAttachment>;
	public var embeds(default, null):Array<Dynamic>; // TODO: convert to embeds
	public var reactions(default, null):Array<Reaction>;
	public var nonce(default, null):String;
	public var pinned:Bool;
	public var webhookID(default, null):String;
	
	public var containsMembers(default, null):Bool = false;

	public function new(data:Dynamic) 
	{
		parseData(data);
	}
	
	private function parseData(data:MessagePackage)
	{
		this.id = data.id;
		this.channelID = data.channel_id; 
		this.author = new User(data.author);
		this.content = data.content; 
		this.timestamp = data.timestamp;
		this.editedTimestamp = data.edited_timestamp;
		this.tts = data.tts;
		this.mentionEveryone = data.mention_everyone;
		
		this.mentions = new Array<User>();
		for (rawUser in data.mentions) {
			this.mentions.push(new User(rawUser));
		}
		
		this.mentionRoleIDs = data.mention_roles;
		
		this.attachments = new Array<MessageAttachment>();
		for (rawAttachment in data.attachments) {
			this.attachments.push(new MessageAttachment(rawAttachment));
		}
		
		this.embeds = data.embeds; // TODO: parse embds 
		
		this.reactions = new Array<Reaction>();
		if (data.reactions != null) {
			for (rawReaction in data.reactions) {
				this.reactions.push(new Reaction(rawReaction));
			}
		}
		
		this.nonce = data.nonce;
		this.pinned = data.pinned;
		this.webhookID = data.webhook_id;
	}
	
}