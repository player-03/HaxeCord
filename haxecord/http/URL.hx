package haxecord.http;

/**
 * ...
 * @author Billyoyo
 */
class URL
{
	public static var regexURL = ~/^([a-z]+:|)(\/\/[^\/\?:]+|)(:\d+|)([^\?]*|)(\?.*|)/i;

	private var url:String;

	public var protocol:String = "";
	public var host:String = "";
	public var port:String = "";
	public var resource:String = "";
	public var querystring:String = "";

  /**
   * Class instance
   *
   * @param urlString  An URL string in standard format "protocol://host:port/resource?querystring"
   **/
	public function new(urlString:String) {
		url = urlString;

		if (URL.regexURL.match(urlString)) {
			
		  protocol = URL.regexURL.matched(1).substr(0, -1);
		  if ( protocol == null ) protocol = "";
		  
		  host = URL.regexURL.matched(2).substr(2);
		  if ( host == null ) host = "";
		  
		  port = URL.regexURL.matched(3);
		  if ( port == null) port = "";
		  
		  resource = URL.regexURL.matched(4);
		  if ( resource == null ) resource = "/";
		  
		  querystring = URL.regexURL.matched(5);
		  if ( querystring == null ) querystring = "";
		  
		}
		
		if ( resource == "" ) resource = "/";
	}
	
	public function toString():String {
		var protocolFull:String = getProtocol();
		return '$protocolFull$host$port$resource$querystring';
	}
	
	public function merge(url:URL):URL {
		if (protocol == "") protocol = url.protocol;
		if (host == "") host = url.host;
		if (port == "") port = url.port;
		resource = mergeResources(resource, url.resource);
		
		if (resource == "" ) resource = "/";
		// no querystring merging
		return this;
	}

	private function mergeResources(resNew:String, resOriginal:String = "") {
		var result:String;
		var levels:Array<String>;
		if (resNew.substr(0, 1) == "/") {
			levels = resNew.split('/');
		} else {
			levels = resOriginal.split("/");
			levels.pop();
			levels = levels.concat(resNew.split("/"));
		}
		var finish = false;
		do {
			var loop = levels.length;
			var i = 0;
			while (true) {
				if (levels[i] == '..') {
					if (i > 0) levels.splice(i - 1, 2);
					else levels.shift();
					break;
				}
				i++;
				if (i >= loop) {
					finish = true;
				break;
				}
		  }
		} while (!finish);
		result = levels.join('/');
		if (result.substr(0, 1) != '/') result = '/$result';
		return result;
	}
		
	public function isSSL():Bool
	{
		return (protocol == "https") || (protocol == "wss");
	}
	
	public function isHTTP():Bool
	{
		return (protocol.substr(0, 4) == "http");
	}
	
	public function isWS():Bool
	{
		return (protocol.substr(0, 2) == "ws");
	}
	
	public function getProtocol():String
	{
		if (protocol != "") return protocol + "://";
		return "";
	}
	
	public function getPort():Int
	{
		if ( port == "" ) {
			if ( !isSSL() ) {
				return 80;
			} else if ( isHTTP() || isWS() ) {
				return 443;
			}
		} else {
			return Std.parseInt(port.substr(1));
		}
		return 0;
	}
}