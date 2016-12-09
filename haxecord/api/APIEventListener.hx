package haxecord.api;
import haxecord.api.Client;
import haxecord.api.data.BaseChannel;
import haxecord.api.data.Channel;
import haxecord.api.data.Guild;
import haxecord.api.data.Member;
import haxecord.api.data.Message;
import haxecord.api.data.PrivateChannel;
import haxecord.api.data.Role;
import haxecord.api.data.User;
import haxecord.api.data.VoiceChannel;
import haxecord.api.data.VoiceState;

/**
 * ...
 * @author Billyoyo
 */
class APIEventListener
{
	public var client:Client;

	public function new(client:Client) 
	{
		this.client = client;
	}
	
	public function onReady():Void {}
	public function onChannelCreate(channel:BaseChannel):Void {}
	public function onChannelUpdate(channel:BaseChannel):Void {}
	public function onChannelDelete(channel:BaseChannel):Void {}
	public function onGuildJoin(guild:Guild):Void {}
	public function onGuildUpdate(guild:Guild):Void {}
	public function onGuildDisconnect(guild:Guild):Void {}
	public function onGuildLeave(guild:Guild):Void {}
	public function onBan(guild:Guild, user:User):Void {}
	public function onUnban(guild:Guild, user:User):Void {}
	public function onEmojisUpdated(guild:Guild):Void {}
	public function onIntegrationsUpdated(guild:Guild):Void {}
	public function onMemberJoin(member:Member):Void {}
	public function onMemberLeave(guild:Guild, user:User):Void {}
	public function onMemberUpdate(member:Member):Void {}
	public function onRoleCreate(guild:Guild, role:Role):Void {}
	public function onRoleUpdate(guild:Guild, role:Role):Void {}
	public function onRoleDelete(guild:Guild, role:Role):Void {}
	public function onMessage(message:Message):Void {}
	public function onMessageEdit(message:Message):Void {}
	public function onMessageDelete(message:Message):Void {}
	public function onTyping(channel:Channel, member:Member):Void {}
	public function onUserUpdate(user:User):Void {}
	public function onVoiceStateUpdate(voiceState:VoiceState):Void {}
	public function onVoiceServerUpdate(guild:Guild):Void {}
	public function onStatusUpdate(user:User):Void {}
}