package haxecord.nekows;
import haxe.io.Bytes;
import haxecord.nekows.WebSocket.OpCode;

/**
 * ...
 * @author Billyoyo
 */
class WebSocketFrame
{
	// used to generate a mask key
	public static function random32():Bytes
	{
		var bytes:Bytes = Bytes.alloc(4);
		for (i in 0...4) {
			bytes.set(i, Std.random(256));
		}
		return bytes;
	}
	
	public var final:Bool;
	public var opcode:OpCode;
	public var data:Bytes;
	public var maskKey:Bytes;
	
	public var dataMasked:Bool;

	public function new(final:Bool, opcode:OpCode, data:Bytes, ?maskKey:Bytes, ?dataMasked:Bool) 
	{
		this.final = final;
		this.opcode = opcode;
		this.data = data;
		this.maskKey = maskKey;
		
		if (dataMasked == null) dataMasked = false;
		this.dataMasked = dataMasked;
	}
	
}