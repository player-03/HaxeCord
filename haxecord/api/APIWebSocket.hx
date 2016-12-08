package haxecord.api;
import haxecord.api.Client;
import haxecord.api.data.Message;
import haxecord.async.EventLoop;
import haxecord.async.Future;
import haxecord.http.URL;
import haxecord.nekows.AsyncWebSocket;
import haxecord.nekows.WebSocket;
import haxecord.nekows.WebSocketMessage;


typedef BaseResponse = {
	var op:Int;
	var d:Dynamic;
	var s:Int;
	var t:String;
}

typedef HelloData = {
	var heartbeat_interval:Int;
	var _trace: Array<String>;
}

/**
 * ...
 * @author Billyoyo
 */
class APIWebSocket
{
	private var websocket:AsyncWebSocket;
	private var websocketFuture:Future;
	private var listeners:Array<APIEventListener> = new Array<APIEventListener>();
	private var heartbeatInterval:Float;
	private var lastHeartbeat:Float;
	private var heartbeatSequence:Int;
	
	public function new(client:Client, url:String, ?origin:String, ?timeperiod:Float) 
	{
		websocket = new AsyncWebSocket(new URL(url), origin, timeperiod);
		// handle heartbeat
		websocket.onUpdate = function(ws:WebSocket):Void {
			if (heartbeatInterval != null) {
				if (Sys.cpuTime() - lastHeartbeat >= heartbeatInterval) {
					sendHeartbeat();
				}
			}
		};
		// handle messages
		websocket.onMessage = function(msg:WebSocketMessage):Void {
			try {
				var payload = msg.getJson();
				var response:BaseResponse = payload;
				if (response.s != null) heartbeatSequence = response.s;
				handleResponse(response);
			} catch ( source:Dynamic ) {
				trace('error encountered parsing message: $msg, $source\n\n');
			}
		};
		// not sure what to do on error, just print it for now
		websocket.onError = function(ws:WebSocket, source:Dynamic):Void {
			trace('error encountered in websocket: $source');
		};
		websocket.onClose = function(ws:WebSocket):Bool {
			if (!websocketFuture.isDone()) return true;
			trace("websocket closing");
			return false;
		};
		websocket.onConnect = function(ws:WebSocket):Void {
			// no logic for onConnect yet
		};
		websocket.onHandshake = function(ws:WebSocket):Void {
			websocket.sendJson({
				"op" : 2,
				"d" : {
						"token" : client.getToken(),
						"large_threshold" : 250,
						"compress" : false,
						"shard" : [client.getShard(), client.getShardCount()],
						"properties" : {
								"$os" : "Windows",
								"$browser" : "HaxeCord",
								"$device" : "HaxeCord",
								"$referrer" : "",
								"$referring_domain" : ""
						}
				}
			});
		}
		
	}
	
	public function start(loop:EventLoop)
	{
		websocketFuture = loop.addTask(websocket);
	}
	
	private function sendHeartbeat() {
		websocket.sendJson({"op": 1, "d" : heartbeatSequence});
	}
	
	private function handleResponseDispatch(response:BaseResponse) {
		/* Events:
		*	 Ready, Resumed, Channel Create, Channel Update,
		*    Channel Delete, Guild Create, Guild Update,
		*    Guild Delete, Guild Ban Add, Guild Ban Remove,
		*    Guild Emojis Update, Guild Integrations Update,
		*    Guild Member Add, Guild Member Remove,
		*    Guild Member Update, Guild Members Chunk,
		*    Guild Role Create, Guild Role Update, Guild Role Delete,
		*    Message Create, Message Update, Message Delete,
		*    Message Delete Bulk, Presence Update, Typing Start,
		*    User Settings Update, User Update, Voice State Update,
		*    Voice Server Update
		*/ 
		var event:EventType = APIWebSocket.getEventType(response.t);
		dispatchEvent(event, response.d);
	}
	
	public function dispatchEvent(event:EventType, data:Dynamic) {
		if (event == EventType.MESSAGE_CREATE) {
			var message:Message = new Message(data);
			for (listener in listeners) {
				listener.onMessage(message);
			}
		}
	}
	
	
	
	private function handleResponseReconnect(response:BaseResponse) {
		trace("told to reconnect, disconnecting");
		// will handle reconnect logic later
		websocket.disconnect();
	}
	
	private function handleResponseHello(response:BaseResponse) {
		trace("hello recieved");
		var data:HelloData = response.d;
		heartbeatInterval = data.heartbeat_interval / 1000;
		lastHeartbeat = Sys.cpuTime();
	}
	
	private function handleResponseInvalidSession(response:BaseResponse) {
		trace("invalid session, disconnecting");
		websocket.disconnect();
	}
	
	private function handleResponseHeartbeatACK(response:BaseResponse) {
		trace("hearbeat ack recieved");
	}
	
	private function handleResponse(response:BaseResponse) {
		switch(response.op) {
			case 0: handleResponseDispatch(response);       // dispatch event
			case 7: handleResponseReconnect(response);      // reconnect
			case 9: handleResponseInvalidSession(response); // invalid session
			case 10: handleResponseHello(response);         // hello
			case 11: handleResponseHeartbeatACK(response);  // heartbeat ack
			default: 0;
		}
	}
	
	public function addListener(listener:APIEventListener):APIWebSocket {
		listeners.push(listener);
		return this;
	}
	
	public function addListeners(listeners:Array<APIEventListener>):APIWebSocket {
		this.listeners = this.listeners.concat(listeners);
		return this;
	}
	
	public function removeListener(listener:APIEventListener):APIWebSocket {
		listeners.remove(listener);
		return this;
	}
	
	public static function getEventType(eventName:String):EventType
	{
		return switch(eventName) {
			case "READY": EventType.READY;
			case "RESUMED": EventType.RESUMED;
			case "CHANNEL_CREATE": EventType.CHANNEL_CREATE;
			case "CHANNEL_UPDATE": EventType.CHANNEL_UPDATE;
			case "CHANNEL_DELETE": EventType.CHANNEL_DELETE;
			case "GUILD_CREATE": EventType.GUILD_CREATE;
			case "GUILD_UPDATE": EventType.GUILD_UPDATE;
			case "GUILD_DELETE": EventType.GUILD_DELETE;
			case "GUILD_BAN_ADD": EventType.GUILD_BAN_ADD;
			case "GUILD_BAN_REMOVE": EventType.GUILD_BAN_REMOVE;
			case "GUILD_EMOJIS_UPDATE": EventType.GUILD_EMOJIS_UPDATE;
			case "GUILD_INTEGRATIONS_UPDATE": EventType.GUILD_INTEGRATIONS_UPDATE;
			case "GUILD_MEMBER_ADD": EventType.GUILD_MEMBER_ADD;
			case "GUILD_MEMBER_REMOVE": EventType.GUILD_MEMBER_REMOVE;
			case "GUILD_MEMBER_UPDATE": EventType.GUILD_MEMBER_UPDATE;
			case "GUILD_MEMBERS_CHUNK": EventType.GUILD_MEMBERS_CHUNK;
			case "GUILD_ROLE_CREATE": EventType.GUILD_ROLE_CREATE;
			case "GUILD_ROLE_UPDATE": EventType.GUILD_ROLE_UPDATE;
			case "GUILD_ROLE_DELETE": EventType.GUILD_ROLE_DELETE;
			case "MESSAGE_CREATE": EventType.MESSAGE_CREATE;
			case "MESSAGE_UPDATE": EventType.MESSAGE_UPDATE;
			case "MESSAGE_DELETE": EventType.MESSAGE_DELETE;
			case "MESSAGE_DELETE_BULK": EventType.MESSAGE_DELETE_BULK;
			case "PRESENCE_UPDATE": EventType.PRESENCE_UPDATE;
			case "TYPING_START": EventType.TYPING_START;
			case "USER_SETTINGS_UPDATE": EventType.USER_SETTINGS_UPDATE;
			case "USER_UPDATE": EventType.USER_UPDATE;
			case "VOICE_STATE_UPDATE": EventType.VOICE_STATE_UPDATE;
			case "VOICE_SERVER_UPDATE": EventType.VOICE_SERVER_UPDATE;
			default: EventType.UNKNOWN;
		}
	}
	
}