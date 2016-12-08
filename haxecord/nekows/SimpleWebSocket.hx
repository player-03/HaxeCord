package haxecord.nekows;
import haxe.io.Bytes;
import haxecord.nekows.WebSocket.OpCode;
import haxe.Json;

enum Fragment {
	AUTO;
	NONE;
	SET(number:Int);
}

/**
 * ...
 * @author Billyoyo
 */
class SimpleWebSocket extends WebSocket
{
	
	public function sendBinary(bytes:Bytes, ?fragments:Fragment)
	{
		sendBytes(bytes, OpCode.BINARY, fragments, false);
	}
	
	public function sendText(message:String, ?fragments:Fragment) {
		sendBytes(Bytes.ofString(message), OpCode.TEXT, fragments);
	}
	
	public function sendJson(data:Dynamic, ?fragments:Fragment) {
		sendText(Json.stringify(data));
	}
	
	public function queueBinary(bytes:Bytes, ?fragments:Fragment)
	{
		sendBytes(bytes, OpCode.BINARY, fragments, true);
	}
	
	public function queueText(message:String, ?fragments:Fragment) {
		sendBytes(Bytes.ofString(message), OpCode.TEXT, fragments, true);
	}
	
	public function queueJson(data:Dynamic, ?fragments:Fragment) {
		queueText(Json.stringify(data));
	}
	
	public function sendBytes(bytes:Bytes, opcode:OpCode, ?fragments:Fragment, ?queue:Bool)
	{
		var frameSender:WebSocketFrame-> Void = sendFrame;
		if (queue) frameSender = queueSendFrame;
		
		if (fragments == null) fragments = Fragment.NONE;
		if (fragments == Fragment.AUTO) {
			if (bytes.length < 100000) fragments = Fragment.NONE;
			else fragments = Fragment.SET(Math.floor(bytes.length / 100000));
		}
		
		switch(fragments) {
			case Fragment.NONE: frameSender(new WebSocketFrame(true, opcode, bytes, WebSocketFrame.random32()));
			case Fragment.SET(number): sendFramedBytes(bytes, opcode, number, queue);
			default: trace('fragment somehow still AUTO?');
		}
	}
	
	public function sendFramedBytes(bytes:Bytes, opcode:OpCode, number:Int, ?queue:Bool)
	{
		var frameSender:WebSocketFrame-> Void = sendFrame;
		if (queue) frameSender = queueSendFrame;
		
		var blockLength:Int = Math.floor(bytes.length / number);
		for (i in 0...number) {
			if (i < number - 1) {
				frameSender(new WebSocketFrame(false, opcode, bytes.sub(i * blockLength, blockLength), WebSocketFrame.random32()));
			} else {
				frameSender(new WebSocketFrame(true, opcode, bytes.sub(i * blockLength, bytes.length - (i * blockLength)), WebSocketFrame.random32()));
			}
		}
	}
	
}