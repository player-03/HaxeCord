package haxecord.api;
import haxecord.api.APIEventListener;
import haxecord.api.data.Channel;
import haxecord.api.data.Member;
import haxecord.api.data.User;
import haxecord.api.data.PrivateChannel;
import haxecord.api.data.Guild;
import haxecord.api.data.VoiceChannel;
import haxecord.async.EventLoop;
import haxecord.api.APIWebSocket;
import haxecord.async.Future;
import haxecord.async.FutureFactory;
import haxecord.http.HTTPRequest;
import haxecord.api.data.Message;
import haxe.Json;



/**
 * ...
 * @author Billyoyo
 */
class Client implements FutureFactory
{
	public var token(default, null):String;
	public var shard(default, null):Int;
	public var shardCount(default, null):Int;
	private var websocket:APIWebSocket;
	public var loop(default, null):EventLoop;
	public var http(default, null):APIHTTP;
	private var tempListeners:Array<APIEventListener> = new Array<APIEventListener>();
	private var boundFuture:Future;
	
	private var messageHistory:Map<String, Message> = new Map<String, Message>();
	private var messageOrder:Array<String> = new Array<String>();
	private var messageHistoryLimit:Int = 100000;
	
	public var me:User;
	public var privateChannels:Map<String,PrivateChannel> = new Map<String, PrivateChannel>();
	public var guilds:Map<String,Guild> = new Map<String,Guild>();
	
	public var sessionID(default, null):String;
	
	private function min(x:Int, y:Int):Int 
	{
		if (x < y) return x;
		else return y;
	}

	public function new(?messageLimit:Int, ?limiter:Float) 
	{
		if (messageLimit != null) messageHistoryLimit = min(100, messageLimit);
		loop = new EventLoop(limiter);
		http = new APIHTTP(this, loop);
	}
	
	public function storeMessage(message:Message)
	{
		messageHistory.set(message.id, message);
		messageOrder.push(message.id);
		if (messageOrder.length >= messageHistoryLimit) {
			var oldestMessage:String = messageOrder.shift();
			messageHistory.remove(oldestMessage);
		}
	}
	
	public function unstoreMessage(message:Message)
	{
		messageHistory.remove(message.id);
		messageOrder.remove(message.id);
	}
	
	public function getMessage(id:String)
	{
		return messageHistory.get(id);
	}
	
	public function sendMessage(destination:String, message:String, ?callback:Message->Void, ?error:String->Void):Future
	{
		var future:Future = http.createMessage(destination, {"content": message}, callback, error);
		if (boundFuture != null) boundFuture.setChild(future);
		future.factory = this;
		return future;
	}
	
	public function addListener(listener:APIEventListener)
	{
		if (websocket != null) {
			websocket.addListener(listener);
		} else {
			tempListeners.push(listener);
		}
		return this;
	}
	
	public function removeListener(listener:APIEventListener)
	{
		if (websocket != null) {
			websocket.removeListener(listener);
		} else {
			tempListeners.remove(listener);
		}
		return this;
	}
	
	public function getGuild(id:String):Guild {
		if (id == null) return null;
		return guilds.get(id);
	}
	
	public function getMembers(id:String):Array<Member> {
		var members:Array<Member> = new Array<Member>();
		var member:Member;
		for (guild in guilds) {
			member = guild.getMember(id);
			if (member != null) members.push(member);
		}
		return members;
	}
	
	public function getChannel(id:String):Channel {
		var channel:Channel;
		for (guild in guilds) {
			channel = guild.getChannel(id);
			if (channel != null) break;
		}
		return channel;
	}
	
	public function getVoiceChannel(id:String):VoiceChannel {
		var channel:VoiceChannel = null;
		for (guild in guilds) {
			var channel = guild.getVoiceChannel(id);
			if (channel != null) break;
		}
		return channel; 
	}
	
	public function getToken() {
		return token;
	}
	
	public function getShardCount() {
		return shardCount;
	}
	
	public function getShard() {
		return shard;
	}
	
	public function setSession(session:String) {
		sessionID = session;
	}
	
	public function run(token:String, ?shard:Int, ?shardCount:Int) {
		if (shard == null) shard = 0;
		if (shardCount == null) shardCount = 1;
		
		this.token = token;
		this.shard = shard;
		this.shardCount = shardCount;
		
		websocket = new APIWebSocket(this, "wss://gateway.discord.gg/?v=6&encoding=json");
		websocket.addListeners(tempListeners);
		tempListeners = null;
		
		websocket.start(loop);
	}
	
	public function bindFuture(future:Future)
	{
		boundFuture = future;
	}
}