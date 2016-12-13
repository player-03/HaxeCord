package haxecord.api.data;
import haxecord.utils.DateTime;

typedef MemberPackage = {
	var user:Dynamic;
	@:optional var nick:String;
	var roles:Array<String>;
	var joined_at:String;
	var deaf:Bool;
	var mute:Bool;
}

typedef MemberUpdatePackage = {
	var roles:Array<String>;
	var user:Dynamic;
	var nick:String;
}



/**
 * ...
 * @author Billyoyo
 */
class Member extends User
{
	
	
	public var nick(default, null):String;
	public var roles(default, null):Array<Role>;
	public var joinedAt(default, null):DateTime;
	public var deaf(default, null):Bool;
	public var mute(default, null):Bool;
	public var guild(default, null):Guild;
	
	public var isPartial(default, null):Bool;

	public function new(guild:Guild, data:MemberPackage, ?partial:Bool) 
	{
		if (partial == null) partial = false;
		isPartial = partial;
		
		super(data.user);
		this.guild = guild;
		if (partial != true) parseMemberData(data);
	}
	
	private function parseMemberData(data:MemberPackage)
	{
		this.nick = data.nick;
		
		this.roles = new Array<Role>();
		for (role in this.guild.roles) {
			if (data.roles.indexOf(role.id) != -1) {
				this.roles.push(role);
				break;
			}
		}
		
		if (data.joined_at != null) this.joinedAt = DateTime.fromString(data.joined_at);
		this.deaf = data.deaf;
		this.mute = data.mute;
	}
	
	public function updateMemberData(data:MemberUpdatePackage)
	{
		parseData(data.user);
		this.nick = data.nick;
		
		this.roles = new Array<Role>();
		for (role in this.guild.roles) {
			if (data.roles.indexOf(role.id) != -1) {
				this.roles.push(role);
				break;
			}
		}
	}
}