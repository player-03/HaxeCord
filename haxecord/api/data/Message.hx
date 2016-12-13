package haxecord.api.data;
import haxecord.api.Client;
import haxecord.utils.DateTime;
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

typedef IDsHelper = {
	var ids:Array<String>;
}

/**
 * ...
 * @author Billyoyo
 */
class Message
{
	public static function getIDs(data:IDsHelper):Array<String>
	{
		return data.ids;
	}
	
	public var id(default, null):String;
	
	public var channel(default, null):BaseChannel; 
	public var guild(default, null):Guild; 
	
	public var author(default, null):User;
	public var content(default, null):String;
	public var timestamp(default, null):DateTime; // TODO: convert to timestamp
	public var editedTimestamp(default, null):DateTime; // TODO: convert to timestamp
	public var tts(default, null):Bool;
	public var mentionEveryone(default, null):Bool;
	public var mentions(default, null):Array<User>;
	public var roleMentions(default, null):Array<Role>;
	public var attachments(default, null):Array<MessageAttachment>;
	public var embeds(default, null):Array<Dynamic>; // TODO: convert to embeds
	public var reactions(default, null):Array<Reaction>;
	public var nonce(default, null):String;
	public var pinned:Bool;
	public var webhookID(default, null):String;
	
	public var containsMembers(default, null):Bool = false;

	public function new(client:Client, data:Dynamic) 
	{
		parseData(client, data);
	}
	
	private function parseData(client:Client, data:MessagePackage)
	{
		this.id = data.id;
		
		this.channel = client.getChannel(data.channel_id);
		if (this.channel == null) this.channel = client.privateChannels.get(data.channel_id);
		else this.guild = cast(this.channel, Channel).guild;
		
		this.author = new User(data.author);
		
		if (this.guild != null) {
			var member:Member = this.guild.getMember(this.author.id);
			if (member != null) this.author = member;
		}
		
		this.content = data.content; 
		if (data.timestamp != null) this.timestamp = DateTime.fromString(data.timestamp);
		if (data.edited_timestamp != null) this.editedTimestamp = DateTime.fromString(data.edited_timestamp);
		this.tts = data.tts;
		this.mentionEveryone = data.mention_everyone;
		
		this.mentions = new Array<User>();
		for (rawUser in data.mentions) {
			var user:User = new User(rawUser);
			if (this.guild != null) {
				var member:Member = guild.getMember(user.id);
				if (member != null) user = member;
			}
			this.mentions.push(user);
		}
		
		this.roleMentions = new Array<Role>();
		if (this.guild != null) {
			for (roleId in data.mention_roles) {
				var role:Role = this.guild.getRole(roleId);
				if (role != null) roleMentions.push(role);
			}
		}
		
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
	
	public function updateMessageData(client:Client, data:MessagePackage) 
	{
		if (data.id != null) this.id = data.id;
		
		if (data.channel_id != null) {
			this.channel = client.getChannel(data.channel_id);
			if (this.channel == null) this.channel = client.privateChannels.get(data.channel_id);
			else this.guild = cast(this.channel, Channel).guild;
		}
		
		if (data.author != null) {
			this.author = new User(data.author);
			
			if (this.guild != null) {
				var member:Member = this.guild.getMember(this.author.id);
				if (member != null) this.author = member;
			}
		}
		
		if (data.content != null) this.content = data.content; 
		if (data.timestamp != null) this.timestamp = DateTime.fromString(data.timestamp);
		if (data.edited_timestamp != null) this.editedTimestamp = DateTime.fromString(data.edited_timestamp);
		if (data.tts != null) this.tts = data.tts;
		if (data.mention_everyone != null) this.mentionEveryone = data.mention_everyone;
		
		if (data.mentions != null) {
			this.mentions = new Array<User>();
			for (rawUser in data.mentions) {
				var user:User = new User(rawUser);
				if (this.guild != null) {
					var member:Member = guild.getMember(user.id);
					if (member != null) user = member;
				}
				this.mentions.push(user);
			}
		}
		
		if (data.mention_roles != null) {
			this.roleMentions = new Array<Role>();
			if (this.guild != null) {
				for (roleId in data.mention_roles) {
					var role:Role = this.guild.getRole(roleId);
					if (role != null) roleMentions.push(role);
				}
			}
		}
		
		if (data.attachments != null) {
			this.attachments = new Array<MessageAttachment>();
			for (rawAttachment in data.attachments) {
				this.attachments.push(new MessageAttachment(rawAttachment));
			}
		}
		
		if (data.embeds != null) this.embeds = data.embeds; // TODO: parse embds 
		
		if (data.reactions != null) {
			this.reactions = new Array<Reaction>();
			for (rawReaction in data.reactions) {
				this.reactions.push(new Reaction(rawReaction));
			}
		}
		
		if (data.nonce != null) this.nonce = data.nonce;
		if (data.pinned != null) this.pinned = data.pinned;
	}
	
}