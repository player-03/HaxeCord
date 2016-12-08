package haxecord.nekows;
import haxe.io.Bytes;
import haxecord.nekows.WebSocket.OpCode;
import haxe.Json;
import haxe.zip.Compress;

/**
 * ...
 * @author Billyoyo
 */
class WebSocketMessage
{
	public var source:WebSocket;
	public var data:Bytes;
	public var opcode:OpCode;

	public function new(source:WebSocket, data:Bytes, opcode:OpCode) 
	{
		this.source = source;
		this.data = data;
		this.opcode = opcode;
	}
	
	public function getString():String
	{
		return data.toString();
	}
	
	public function getJson()
	{
		return Json.parse(data.toString());
	}
	
}