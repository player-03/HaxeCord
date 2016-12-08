package haxecord.http;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxecord.async.AsyncEvent;
import haxecord.async.Cancel;
import haxecord.async.Future;
import haxecord.http.HTTPException;
import haxecord.http.URL;
import sys.net.Host;

private typedef AbstractSocket = {
  var input(default, null):haxe.io.Input;
  var output(default, null):haxe.io.Output;

  function connect(host:Host, port:Int):Void;
  function setTimeout(t:Float):Void;
  function write(str:String):Void;
  function close():Void;
  function shutdown(read:Bool, write:Bool):Void;
}

private typedef SocketSSL = sys.ssl.Socket;
private typedef SocketTCP = sys.net.Socket;

private enum ContentKind {
  XML;
  JSON;
  IMAGE;
  TEXT; //generic text type
  BYTES; //generic binary type
}

private typedef ContentKindMatch = {
  var kind:ContentKind;
  var regex:EReg;
}

private enum HTTPTransferMode 
{
	UNDEFINED;
	FIXED;
	CHUNKED;
}

/**
 * ...
 * @author Billyoyo
 */
class HTTPRequest implements AsyncEvent
{
	
	private var socket:AbstractSocket;
	private var socketConnected:Bool = false;
	
	private var thisFuture:Future = null;
	
	public var url:URL;
	private var httpVersion:String = "1.1";
	private var httpMethod:String = "GET";
	private var httpUserAgent:String = "haxecord-billyoyo";
	private var httpHost:String = "";
	private var httpHeaders:Map<String, String> = new Map<String, String>();
	private var httpContent:Dynamic = null;
	private var httpContentType:String = "";
	private var httpContentLength:Int = 0;
	
	private var responseHeaders:Map<String, String> = new Map<String, String>();
	private var responseStatus:Int = 0;
	private var responseError:Dynamic = null;
	private var responseRedirectChain:Array<String> = new Array<String>();
	private var responseMaxRedirects:Int = 5;
	
	private var responseContentLoaded:Int = 0;
	private var responseContentBytes:Bytes = null;
	private var responseContentNBlocks:Int = 0;
	private var responseContentCurBlock:Int = 0;
	private var responseContentBytesLeft:Int = 0;
	private var responseContentBytesLoaded:Int = 0;
	private var responseContentMode:HTTPTransferMode = null;
	private var responseContentLength:Int = 0;
	private var responseContentBuffer:BytesBuffer = null;
	
	private var responseHeadersCompleted:Bool = false;
	private var responseCompleted:Bool = false;
	
	private var callbackComplete:HTTPRequest->HTTPResponse->Void;
	private var callbackError:HTTPRequest->HTTPException->Void;
	
	private var debug:Bool = false;
	
	public function new(url:URL, ?debug:Bool) 
	{
		this.url = url;
		
		if (debug != null)
		{
			this.debug = debug;
		}
	}
	
	private function log(message:String)
	{
		if (debug) {
			trace(message);
		}
	}
	
	public function setCompleteCallback(callback:HTTPRequest->HTTPResponse->Void)
	{
		callbackComplete = callback;
	}
	
	public function setErrorCallback(callback:HTTPRequest->HTTPException->Void)
	{
		callbackError = callback;
	}
	
	public function setHeaders(rawHeaders:Map<String, String>) 
	{
		httpHeaders = new Map<String, String>();
		updateHeaders(rawHeaders);
	}
	
	public function updateHeaders(rawHeaders:Map<String, String>)
	{
		for (key in rawHeaders.keys())
		{
			addHeader(key, rawHeaders.get(key));
		}
	}
	
	public function addHeader(key:String, value:String)
	{
		var lowerCaseKey:String = key.toLowerCase();
		if (lowerCaseKey == "user-agent") {
			httpUserAgent = value;
		} else if (lowerCaseKey == "host") {
			httpHost = value;
		} else if (lowerCaseKey == "content-type") {
			httpContentType = value;
		} else if (lowerCaseKey == "content-length") {
			httpContentLength = Std.parseInt(value);
		} else {
			httpHeaders.set(key, value);
		}
	}
	
	public function getUserAgent()
	{
		return httpUserAgent;
	}
	
	public function getHost()
	{
		return httpHost;
	}
	
	public function setContentType(contentType:String)
	{
		httpContentType = contentType;
	}
	
	public function getContentType()
	{
		return httpContentType;
	}
	
	public function getContentLength()
	{
		return httpContentLength;
	}
	
	public function setVersion(version:String)
	{
		if (!socketConnected) httpVersion = version;
	}
	
	public function getVersion() {
		return httpVersion;
	}
	
	public function setMethod(method:String)
	{
		if (!socketConnected) httpMethod = method.toUpperCase();
	}
	
	public function getMethod()
	{
		return httpMethod;
	}
	
	public function setContent(content:Dynamic)
	{
		httpContent = content;
	}
	
	public function getContent()
	{
		return httpContent;
	}
	
	public function deleteHeader(key:String)
	{
		httpHeaders.remove(key);
	}
	
	private function isBinary(content:Dynamic)
	{
		return HTTPRequest.determineIsBinary(HTTPRequest.determineContentKind(content));
	}
	
	private function _getHeader(headers:Map<String,String>, key:String)
	{
		if (headers.exists(key)) {
			return headers.get(key);
		}
		return "";
	}
	
	public function getHeader(key)
	{
		return httpHeaders.get(key);
	}
	
	public function getHeaderKeys()
	{
		return httpHeaders.keys();
	}
	
	public function connectSocket()
	{
		log("connecting to socket...");
		responseHeadersCompleted = false;
		responseHeaders = new Map<String, String>();
		responseStatus = 0;
		
		
		try {
			if ( url.isSSL() ){
				socket = new SocketSSL();
			} else {
				socket = new SocketTCP();
			}
		
			socket.connect(new Host(url.host), url.getPort());
			socketConnected = true;
			log("socket connected");
		} catch ( source:Dynamic ) {
			responseError = new HTTPException(source, "Failed to connect socket", 0);
			responseStatus = 0;
			responseCompleted = true;
			return;
		}
			
		
		try {
			log("sending request");
			socket.output.writeString('${httpMethod} ${url.resource}${url.querystring} HTTP/$httpVersion\r\n');
			socket.output.writeString('User-Agent:$httpUserAgent\r\n');
			socket.output.writeString('Host:${url.host}\r\n');
			
			log("... (sending headers)");
			for (key in httpHeaders.keys()) {
				var value = httpHeaders.get(key);
				socket.output.writeString('$key:$value\r\n');
			}
			
			log("... (sending content)");
			if (httpContent != null) {
				socket.output.writeString('Content-Type:${httpContentType}\r\n');
				socket.output.writeString('Content-Length:' + httpContent.length + '\r\n');
				socket.output.writeString('\r\n');
				if (isBinary(httpContentType)) {
					socket.output.writeBytes(cast(httpContent, Bytes), 0, httpContent.length);
				} else {
					socket.output.writeString(httpContent.toString());
				}
			}
			
			socket.output.writeString('\r\n');
		} catch ( source:Dynamic ) {
			responseError = new HTTPException(source, "Failed to write request to socket", 0);
			responseStatus = 0;
			socket.close();
			socketConnected = false;
			responseCompleted = true;
			return;
		}
	}
	
	public function readHeader() 
	{
		log("reading header!");
		
		var line:String = "";
		try {
			line = StringTools.ltrim(socket.input.readLine());
        } catch (source:Dynamic) {
			// error (probably unexpected connection terminated)
			responseError = new HTTPException(source, 'Failed to read header', 0);
			line = '';
			responseStatus = 0;
			try {
				socket.close();
			} catch (err:Dynamic)
			{
				log("Unexpected socket closure");
			}
			socketConnected = false;
        }
		
		if (line == "") {
			responseHeadersCompleted = true;
			return;
		}
		
		if (responseStatus == 0) {
          var r = ~/^HTTP\/\d+\.\d+ (\d+)/;
          r.match(line);
          responseStatus = Std.parseInt(r.matched(1));
        } else {
          var a = line.split(':');
          var key = a.shift().toLowerCase();
          responseHeaders.set(key, StringTools.ltrim(a.join(':')));
		}
		
	}
	
	public function readContent()
	{
		try {
			
			if (responseContentMode == null) {
				responseContentLength = Std.parseInt(_getHeader(responseHeaders, "content-length"));
				
				responseContentMode = HTTPTransferMode.UNDEFINED;
				if (responseContentLength > 0) responseContentMode = HTTPTransferMode.FIXED;
				if (_getHeader(responseHeaders, 'transfer-encoding') == 'chunked') responseContentMode = HTTPTransferMode.CHUNKED;
			}
			
			if (responseContentLength == null || responseContentMode == null) {
				return;
			}
			log('reading content: $responseContentLength and mode: $responseContentMode');
			
			switch (responseContentMode) {
				
				case HTTPTransferMode.UNDEFINED:
					try {
						responseContentBytes = socket.input.readAll();
					} catch (source:Dynamic) {
						responseError = new HTTPException(source, "Failed to read content (Mode: UNDEFINED)", 0);
						responseStatus = 0;
						responseCompleted = true;
						socket.close();
						socketConnected = false;
						return;
					}
					responseContentLength = responseContentBytes.length;
					responseCompleted = true;
					// finished loading
				
				case HTTPTransferMode.FIXED:
					var block_len = 1024 * 1024;

					if (responseContentBytes == null)  { 
						responseContentBytes = Bytes.alloc(responseContentLength);
						responseContentNBlocks = Math.ceil(responseContentLength / block_len);
						responseContentBytesLeft = responseContentLength;
						responseContentBytesLoaded = 0;
						responseContentCurBlock = 0;
					}
					
					var actual_block_len = (responseContentBytesLeft > block_len)?block_len:responseContentBytesLeft;
					try {
						socket.input.readFullBytes(responseContentBytes, responseContentBytesLoaded, actual_block_len);
					} catch (source:Dynamic) {
						responseError = new HTTPException(source, "Failed to read content (Mode: FIXED)", 0);
						responseStatus = 0;
						responseCompleted = true;
						socket.close();
						socketConnected = false;
						return;
					}
					
					responseContentBytesLeft -= actual_block_len;
					responseContentBytesLoaded += actual_block_len;
					
					responseContentCurBlock += 1;
					if (responseContentCurBlock >= responseContentNBlocks) responseCompleted = true;
					
				case HTTPTransferMode.CHUNKED:
					
					if (responseContentBuffer == null) {
						responseContentBuffer = new BytesBuffer();
						try {
							var v:String = socket.input.readLine();
							var chunk:Int = Std.parseInt('0x$v');
							if (chunk == 0) {
								responseContentBytes = responseContentBuffer.getBytes();
								responseContentLength = responseContentBytesLoaded;
								
								responseContentBuffer = null;
								responseCompleted = true;
							} else {
								var bytes = socket.input.read(chunk);
								responseContentBytesLoaded += chunk;
								responseContentBuffer.add(bytes);
								socket.input.read(2);
							}
						} catch (source:Dynamic) {
							responseError = new HTTPException(source, "Failed to read content (Mode: CHUNKED)", 0);
							responseStatus = 0;
							responseCompleted = true;
							socket.close();
							socketConnected = false;
							return;
						}
					}
				
			}
		} catch (source:Dynamic) {
			responseError = new HTTPException(source, "Failed to read content (generic)", 0);
			responseStatus = 0;
			responseCompleted = true;
			socket.close();
			socketConnected = false;
			return;
		}
	}
	
	public function await(?timeout:Float)
	{
		if (!socketConnected) connectSocket();
		while (!asyncCheck(thisFuture) && (timeout == null || timeout > 0)) {
			if (timeout != null) timeout -= 0.1;
			Sys.sleep(0.1);
		}
		if (timeout != null && timeout <= 0) {
			if (responseError == null) responseError = new HTTPException(null, "await timed out", 0);
		}
		asyncCallback();
	}
	
	public function asyncStart(future:Future) 
	{
		thisFuture = future;
		connectSocket();
	}
	
	public function asyncCancel(reason:Cancel) 
	{
		if (socketConnected) {
			socket.close();
			socketConnected = false;
		}
		if (responseError == null) {
			responseError = new HTTPException(reason, "Future was cancelled", 0);
		}
		responseStatus = 0;
	}
	
	public function asyncCallback() 
	{
		trace("got callback");
		if (responseError != null) {
			// error was encountered :(
			if (callbackError != null) callbackError(this, responseError);
		} else {
			if (socketConnected) {
				socket.close();
			}
			// content was actually read!
			if (callbackComplete != null) callbackComplete(this, new HTTPResponse(responseStatus, responseRedirectChain, responseContentBytes, 
												responseContentLength, responseHeaders));
		}
	}
	
	public function asyncCheck(future:Future):Bool 
	{
		if (responseCompleted) return true;
		
		if (!responseHeadersCompleted)
		{
			readHeader();
			if (responseHeadersCompleted) {
				log("response headers completed...");
				if (responseError != null) {
					// an error was encountered, so we'll stop the future and conclude the request
					if (socketConnected) {
						socket.close();
						socketConnected = false;
					}
					return true;
				}
				// check if we're being redirected
				if (responseStatus == 301 || responseStatus == 302 || responseStatus == 303 || responseStatus == 307) {
					log("we're being redirected!");
					var newlocation = responseHeaders.get('location');
					if (newlocation != "") {
						var newURL = new URL(newlocation);
						newURL.merge(url);
						if (responseRedirectChain.length <= responseMaxRedirects && responseRedirectChain.indexOf(newURL.toString()) == -1) {
							url = newURL;
							responseRedirectChain.push(url.toString());
							socket.close();
							socketConnected = false;
							connectSocket();
						// hit redirect limit or redirect looped, so we need to error
						} else {
							if (responseRedirectChain.length <= responseMaxRedirects) {
								responseError = new HTTPException(null, "Reached the maximum redirect cap", 0);
							} else {
								responseError = new HTTPException(null, "Redirect looped", 0);
							}
							responseStatus = 0;
							socket.close();
							socketConnected = false;
							return true;
						}
					} else {
						// we didn't resolve the location, so lets give up
						responseError = new HTTPException(null, "Couldn't resolve redirect location", 0);
						responseStatus = 0;
						socket.close();
						socketConnected = false;
						return true;
					}
				}
				// otherwise, we can start reading the content
			}
		}
		
		// response has been completed successfully, lets start reading the content
		if (responseHeadersCompleted) {
			readContent();
		}
		
		if (responseCompleted) {
			return true;
		}
		
		return false;
	}
	
	private static var CONTENT_KIND_MATCHES:Array<ContentKindMatch> = [{
			kind:ContentKind.IMAGE,
			regex:~/^image\/(jpe?g|png|gif)/i
		}, {
			kind:ContentKind.XML,
			regex:~/(application\/xml|text\/xml|\+xml)/i
		}, {
			kind:ContentKind.JSON,
			regex:~/^(application\/json|\+json)/i
		}, {
			kind:ContentKind.TEXT,
			regex:~/(^text|application\/javascript)/i
		} //text is the last one
	];

	// The content kind is used to determine if a content is Binary or Text
	public static function determineContentKind(contentType:String):ContentKind {
		var contentKind = ContentKind.BYTES;
		for (el in CONTENT_KIND_MATCHES) {
			if (el.regex.match(contentType)) {
				contentKind = el.kind;
				break;
			}
		}
		trace('content kind: $contentKind found with $contentType');
		return contentKind;
	}

	public static function determineIsBinary(contentKind:ContentKind):Bool {
		if (contentKind == ContentKind.BYTES || contentKind == ContentKind.IMAGE) return true;
		return false;
	}
	
	public function asyncSetup(future:Future):Void {}
}