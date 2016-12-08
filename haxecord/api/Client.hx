package haxecord.api;
import haxecord.api.APIEventListener;
import haxecord.async.EventLoop;
import haxecord.api.APIWebSocket;
import haxecord.async.Future;
import haxecord.async.FutureFactory;
import haxecord.http.HTTP;
import haxecord.http.HTTPException;
import haxecord.http.HTTPRequest;
import haxecord.http.HTTPResponse;
import haxe.Json;

/**
 * ...
 * @author Billyoyo
 */
class Client implements FutureFactory
{
	public var token:String;
	private var shard:Int;
	private var shardCount:Int;
	private var websocket:APIWebSocket;
	private var loop:EventLoop;
	public var http:HTTP;
	private var tempListeners:Array<APIEventListener> = new Array<APIEventListener>();
	private var boundFuture:Future;

	public function new() 
	{
		loop = new EventLoop();
		http = new HTTP(loop);
	}
	
	public function sendMessage(destination:String, message:String):Future
	{
		var future:Future = http.post('https://discordapp.com/api/channels/$destination/messages', {
			"headers" :  [ "Authorization" => 'Bot $token' ],
			"json" : { "content" : message },
			"onComplete" : function(req:HTTPRequest, resp:HTTPResponse) { trace('got response $resp'); },
			"onError": function(req:HTTPRequest, error:HTTPException) { trace('request errored $error'); }
		});
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
	
	public function getToken() {
		return token;
	}
	
	public function getShardCount() {
		return shardCount;
	}
	
	public function getShard() {
		return shard;
	}
	
	public function run(token:String, ?shard:Int, ?shardCount:Int) {
		if (shard == null) shard = 0;
		if (shardCount == null) shardCount = 1;
		
		this.token = token;
		this.shard = shard;
		this.shardCount = shardCount;
		//var resp:HTTPResponse = http.get(""
		
		websocket = new APIWebSocket(this, "wss://gateway.discord.gg/?v=6&encoding=json");
		websocket.addListeners(tempListeners);
		tempListeners = null;
		
		websocket.start(loop);
		loop.run();
	}
	
	public function bindFuture(future:Future)
	{
		boundFuture = future;
	}
}