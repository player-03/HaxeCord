package haxecord.api;
import haxecord.async.EventLoop;
import haxecord.async.Future;
import haxecord.http.HTTP;
import haxecord.http.HTTPException;
import haxecord.http.HTTPRequest;
import haxecord.http.HTTPResponse;

/**
 * ...
 * @author Billyoyo
 */
class APIHTTP extends HTTP
{
	private var client:Client;
	
	public function new(client:Client, ?loop:EventLoop)
	{
		super(loop);
		this.client = client;
	}

	public function sendChannelMessage(destinationID:String, message:String, ?callback:Void->Void, ?error:HTTPException->Void):Future
	{
		return post('https://discordapp.com/api/channels/$destinationID/messages', {
			"headers" :  [ "Authorization" => 'Bot ${client.token}' ],
			"json" : { "content" : message },
			"onComplete" : function(req:HTTPRequest , resp:HTTPResponse) { if (callback != null) callback(); },
			"onError": function(req:HTTPRequest, httperror:HTTPException) { if (error != null) error(httperror);  }
		});
	}
	
}