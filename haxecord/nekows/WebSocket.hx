package haxecord.nekows;
import haxe.crypto.Base64;
import haxe.crypto.Sha1;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesOutput;
import haxe.io.Eof;
import haxe.io.Error;
import haxe.PosInfos;
import haxecord.http.URL;
import sys.net.Host;

private typedef AbstractSocket = {
  var input(default, null):haxe.io.Input;
  var output(default, null):haxe.io.Output;

  function connect(host:Host, port:Int):Void;
  function setTimeout(t:Float):Void;
  function setBlocking(b:Bool):Void;
  function write(str:String):Void;
  function close():Void;
  function shutdown(read:Bool, write:Bool):Void;
}

private typedef SocketSSL = sys.ssl.Socket;
private typedef SocketTCP = sys.net.Socket;

enum WebSocketErrors {
	INVALID_HANDSHAKE_ACCEPT;
	INVALID_HANDSHAKE_STATUS;
	UNSUPPORTED_OPCODE(opcode:Int);
}

enum OpCode 
{
	CONTINUE;
	TEXT;
	BINARY;
	CLOSE;
	PING;
	PONG;
}

/**
 * ...
 * @author Billyoyo
 */
class WebSocket
{
	private var GUID:String = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
	
	private var url:URL;
	private var origin:String;
	private var HTTPString:String = "HTTP";
	private var socket:AbstractSocket;
	private var socketConnected:Bool = false;
	private var secKey:String;
	private var secAccept:String;
	
	private var frameQueue:Array<WebSocketFrame> = new Array<WebSocketFrame>();
	private var sendQueue:Array<WebSocketFrame> = new Array<WebSocketFrame>();
	
	private var awaitingHandshake:Bool = true;
	private var blocking:Bool = false;
	
	public var onMessage:WebSocketMessage-> Void;
	public var onClose:WebSocket->Bool;
	public var onHandshake:WebSocket->Void;
	public var onError:WebSocket->Dynamic->Void;
	public var onConnect:WebSocket->Void;
	public var onUpdate:WebSocket->Void;
	
	public function new(url:URL, ?origin:String, ?blocking:Bool) 
	{
		this.url = url;
		if (url.isSSL()) {
			HTTPString = "HTTPS";
		}
		
		this.origin = origin;
		if (blocking != null) this.blocking = blocking;
	}
	
	public function on(events:Map<String,Dynamic>) {
		for (event in events.keys()) {
			if (event == "message") {
				onMessage = events.get(event);
			} else if (event == "error") {
				onError = events.get(event);
			} else if (event == "connect") {
				onConnect = events.get(event);
			} else if (event == "close") {
				onClose = events.get(event);
			} else if (event == "handshake") {
				onHandshake = events.get(event);
			} else {
				throw 'Invalid event $event';
			}
		}
	}
	
	public function connected():Bool
	{
		return socketConnected;
	}
	
	public function connect()
	{
		if (url.isSSL()) {
			socket = new SocketSSL();
		} else {
			socket = new SocketTCP();
		}
		
		socket.connect(new Host(url.host), url.getPort());
		socket.setBlocking(blocking);
		
		if (url.isSSL()) {
			cast(socket, SocketSSL).handshake();
		}
		
		if (onConnect != null) onConnect(this);
		
		socketConnected = true;
		
		sendHandshake();
	}
	
	public function disconnect()
	{
		trace("WEBSOCKET DISCONNECTING");
		socket.close();
		socketConnected = false;
		socket = null;
		frameQueue = new Array<WebSocketFrame>();
		awaitingHandshake = true;
		secKey = null;
		
		// if onClose returns true, we need to attempt to reconnect
		if (onClose != null) {
			if (onClose(this)) connect();
		}
	}
	
	public function update(?doFrameRead:Bool)
	{
		//trace(" UPDATING ");
		if (doFrameRead == null) doFrameRead = true;
		try {
			if (awaitingHandshake)
			{
				recieveHandshake();
				if (onHandshake != null) {
					onHandshake(this);
				}
			} else {
				if (onUpdate != null) onUpdate(this);
				if (sendQueue.length > 0) {
					var frame:WebSocketFrame = sendQueue.shift();
					sendFrame(frame);
				}
				
				if (doFrameRead) {
					var frame:WebSocketFrame = readNextFrame();
					if (frame.opcode == OpCode.CLOSE) {
						var closeStatus:Int = (frame.data.get(0) << 8) + frame.data.get(1);
						log('CLOSED WITH STATUS: $closeStatus', 4);
						log('CLOSED BYTES: ${frame.data}');
						
						for (i in 0...frame.data.length) {
							var closeStatus:Int = frame.data.get(i);
							log(' ... $closeStatus', 4);
						}
						disconnect();
					} else if (frame.opcode == OpCode.PING) {
						log("PING PING PING", 4);
						sendFrame(new WebSocketFrame(true, OpCode.PONG, frame.data));
					} else if (frame.opcode == OpCode.PONG) {
						log("PONG PONG PONG", 4);
						sendFrame(new WebSocketFrame(true, OpCode.PING, frame.data));
					} else if (frame.opcode == OpCode.CONTINUE) {
						log("CONTINUE", 4);
						return;
					} else {
					
						frameQueue.push(frame);
						
						if (frame.final) {
							var totalLength:Int = 0;
							for (frame in frameQueue) {
								totalLength += frame.data.length;
							}
							
							var data:Bytes = Bytes.alloc(totalLength);
							var j:Int = 0;
							for (frame in frameQueue) {
								if (frame.maskKey != null) {
									for (i in 0...frame.data.length) {
										if (frame.maskKey != null) {
											data.set(j, frame.data.get(i) ^ frame.maskKey.get(i % 4));
										}
										j++;
									}
								} else {
									data.blit(j, frame.data, 0, frame.data.length);
									j+=frame.data.length;
								}
							}
							
							if (onMessage != null) {
								onMessage(new WebSocketMessage(this, data, frame.opcode));
							}
							
							frameQueue = new Array<WebSocketFrame>();
						}
					}
				}
			}
		} catch ( eof:Eof ) {
			// don't need to pass eof errors
		} catch ( source:Dynamic ) {
			if (source == Error.Blocked) { 
				return; // we can ignore blocked errors
			}
			if (onError != null) onError(this, source);
		}
	}
	
	private function writeHeaders(headers:Array<String>)
	{
		var jointHeaders:String = headers.join("\r\n") + "\r\n\r\n";
		log('HEADERS:\n$jointHeaders');
		//var bytes:Bytes = Bytes.ofString(jointHeaders);
		//socket.output.writeBytes(bytes, 0, bytes.length);
		//for (line in headers) {
		//	socket.output.writeString(line + "\r\n");
		//}
		socket.output.writeString(jointHeaders);
		//socket.output.writeString("\r\n");
	}
	
	public function sendHandshake()
	{
		var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
		var key = "";
		for (i in 0...10) key += chars.charAt(Std.int(Math.random() * chars.length));
		secKey = Base64.encode(Bytes.ofString(key));
		secAccept = Base64.encode(Sha1.make(Bytes.ofString(secKey + GUID)));
		
		var headers:Array<String> = [
			'GET ${url.resource}${url.querystring} HTTP/1.1',
			'Host: ${url.host}:${url.getPort()}',
			"Upgrade: websocket",
			"Connection: Upgrade",
			'Sec-WebSocket-Key: $secKey',
			"Sec-WebSocket-Protocol: chat, superchat",
			"Sec-WebSocket-Version: 13",
			'Origin: $origin'
		];
		//if (origin != null) headers.push('Origin: $origin');
		
		writeHeaders(headers);
		
		awaitingHandshake = true;
	}
	
	public function log(msg:String, ?index:Int, ?posInfos:PosInfos)
	{
		if (index == 4) trace(msg, posInfos);
	}
	
	public function recieveHandshake()
	{
		log("awaiting handshake...", 0);
		var line:String = "";
		while ((line = socket.input.readLine()) != "") {
			//trace('line: $line');
			var index = line.indexOf(":");
			// not opening header 
			if (index != -1) {
				// we don't need to worry about Upgrade, Connection & Sec-WebSocket-Protocol
				var key:String = line.substr(0, index);
				log('key: $key', 0);
				
				if (key == "sec-websocket-accept") {
					var responseKey:String = StringTools.ltrim(line.substring(index + 1));
					log('sec-accept-key: $responseKey, looking for: $secAccept', 0);
					if (responseKey != secAccept) {
						throw WebSocketErrors.INVALID_HANDSHAKE_ACCEPT;
						// invalid response accept key
					} else {
						awaitingHandshake = false;
					}
				}
			} else {
				var split:Array<String> = line.split(" ");
				var status:Int = Std.parseInt(split[1]);
				log('status: $status', 0);
				if (status != 101) {
					log('status: $status', 0);
					throw WebSocketErrors.INVALID_HANDSHAKE_STATUS;
					// invalid status, do not establish connection
				}
			}
		}
		log("handshake over", 0);
		
	}
	
	
	private function getBit(n:Int, bit:Int)
	{
		return (n >> bit) & 1;
	}
	
	public function readNextFrame():WebSocketFrame
	{
		/*BYTE 1
		 * 7 6 5 4 3 2 1 0
		 *|F|R|R|R|  OP   |
		 *|I|S|S|S| CODE  |
		 *|N|V|V|V|       |
		 *| |1|2|3|       |
		 */
		var byte1:Int = socket.input.readByte();
		var final:Bool = (byte1 & 0x80) != 0;
		
		var opcode:Int = byte1 & 0x0F;
		
		log('byte1:$byte1 final=$final opcode=$opcode', 1);
		
		/*BYTE 2
		 * 7 6 5 4 3 2 1 0
		 *|M|  PAYLOAD    |
		 *|A|   LENGTH    |
		 *|S|             |
		 *|K|             |
		 */
		var byte2:Int = socket.input.readByte();
		var mask:Int = getBit(byte2, 7);
		var maskKey:Bytes = null;
		var payloadLength:Int = byte2 & 0x7F;
		
		if (payloadLength == 126) {
			//BYTES 3 & 4 are PAYLOAD LENGTH
			log("using bytes 3 & 4 for payload length", 1);
			payloadLength = (socket.input.readByte() << 8) + socket.input.readByte();
		} else if (payloadLength == 127) {
			//BYTES 3, 4, 5, 6, 7, 8, 9 & 10 are PAYLOAD LENGTH
			log("using bytes 3 to 10 for payload length", 1);
			var high = (socket.input.readByte() << 24) + (socket.input.readByte() << 16) + (socket.input.readByte() << 8) + socket.input.readByte();
			var low = (socket.input.readByte() << 24) + (socket.input.readByte() << 16) + (socket.input.readByte() << 8) + socket.input.readByte();
			
			payloadLength = haxe.Int64.toInt(haxe.Int64.make(high, low));
		}
		
		log('byte2: mask=$mask payloadLength=$payloadLength', 1);
		
		// CURRENT BYTE = I
		
		if (mask == 1) {
			//BYTES I+1, I+2, I+3, I+4 are MASK
			log("using 4 bytes for mask key", 1);
			maskKey = socket.input.read(4);
		}
		
		// read application data:
		
		var data:Bytes = socket.input.read(payloadLength);
		log("read bytes");
		
		return new WebSocketFrame(final, getOpCode(opcode), data, maskKey);
	}
	
	public function queueSendFrame(frame:WebSocketFrame) {
		sendQueue.push(frame);
	}
	
	public function queueSendFrames(frames:Array<WebSocketFrame>) {
		sendQueue.concat(frames);
	}
	
	public function sendFrame(frame:WebSocketFrame) {
		var byte1:Int = 0;
		var finali:Int = 0;
		var opcode:Int = convertOpCode(frame.opcode);
		if (frame.final) finali = 1;
		byte1 += finali << 7;
		byte1 += opcode;
		
		log('byte1=$byte1, opcode=$opcode, final=$finali', 3);
		
		socket.output.writeByte(byte1);
		
		var byte2:Int = 0;
		var maski:Int = 0;
		if (frame.maskKey != null) maski = 1;
		byte2 += maski << 7;
		
		
		
		var payloadLength = frame.data.length;
		log('payload length=$payloadLength', 3);
		
		// we can just use the 7 bits
		if (payloadLength < 126) {
			log("payload length < 126, using 7 bits", 3);
			byte2 += payloadLength;
			socket.output.writeByte(byte2);
		// we'll use bytes 3 and 4, and set byte 2 to 126
		} else if (payloadLength < 65535) {
			log("payload length < 65535, using 2 bytes", 3);
			byte2 += 126;
			socket.output.writeByte(byte2);
			
			socket.output.writeByte(payloadLength >> 8 & 0xFF);
			socket.output.writeByte(payloadLength & 0xFF);
		// otherwise we'll use 8 bytes
		} else {
			log("payload length max, using 8 bytes...", 3);
			byte2 += 127;
			socket.output.writeByte(byte2);
			
			// slow approach
			for (i in 0...8) {
				socket.output.writeByte(payloadLength >> 8 * (7 - i) & 0xFF);
			}
		}
		
		log('byte2=$byte2, maski=$maski', 3);
		
		// try and write the mask
		if (frame.maskKey != null) {
			socket.output.writeBytes(frame.maskKey, 0, frame.maskKey.length);
		}
		
		log('outputing data ${frame.data}', 3);
		// write the data
		if (!frame.dataMasked) {
			// mask data when we send it
			for (i in 0...frame.data.length) {
				socket.output.writeByte(frame.data.get(i) ^ frame.maskKey.get(i % 4));
			}
		} else {
			socket.output.writeBytes(frame.data, 0, frame.data.length);
		}
		//return socket.output;
	}
	
	private function getOpCode(opcode:Int) {
		return switch(opcode) {
			case 0x0: OpCode.CONTINUE;
			case 0x1: OpCode.TEXT;
			case 0x2: OpCode.BINARY;
			case 0x8: OpCode.CLOSE;
			case 0x9: OpCode.PING;
			case 0xA: OpCode.PONG;
			default: null; // throw WebSocketErrors.UNSUPPORTED_OPCODE(opcode);
		}
	}
	
	private function convertOpCode(opcode:OpCode) {
		return switch(opcode) {
			case OpCode.CONTINUE: 0x0;
			case OpCode.TEXT: 0x1;
			case OpCode.BINARY: 0x2;
			case OpCode.CLOSE: 0x8;
			case OpCode.PING: 0x9;
			case OpCode.PONG: 0xA;
			default: 0; // throw WebSocketErrors.UNSUPPORTED_OPCODE(0);
		}
	}
}