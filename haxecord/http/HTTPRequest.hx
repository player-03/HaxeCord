package haxecord.http;
import haxe.Http;
import haxe.io.BytesOutput;
import haxecord.async.AsyncEvent;
import haxecord.async.Cancel;
import haxecord.async.Future;

#if sys
/**
 * ...
 * @author Billyoyo
 */
class HTTPRequest implements AsyncEvent
{
	
	private var http:Http;
	private var method:String;
	private var thisFuture:Future;
	
	public function new(http:Http, ?method:String) 
	{
		this.http = http;
		this.method = method;
	}
	
	public function asyncStart(future:Future) 
	{
		thisFuture = future;
		
		var output:BytesOutput = new BytesOutput();
		var onError:String->Void = http.onError;
		var error:Bool = false;
		http.onError = function(e:String) {
			#if neko
			http.responseData = neko.Lib.stringReference(output.getBytes());
			#else
			http.responseData = output.getBytes().toString();
			#end
			error = true;
			// Resetting http.onError before calling it allows for a second "retry"
			// request to be sent without onError being wrapped twice
			http.onError = onError;
			http.onError(e);
		}
		
		http.customRequest(method == "POST", output, null, method);
		
		if(!error)
		#if neko
			http.onData(http.responseData = neko.Lib.stringReference(output.getBytes()));
		#else
			http.onData(http.responseData = output.getBytes().toString());
		#end
	}
	
	public function asyncCancel(reason:Cancel) 
	{
		http.cancel();
	}
	
	public function asyncCheck(future:Future):Bool 
	{
		return http.responseData != null;
	}
	
	public function asyncCallback() {}
	
	public function asyncSetup(future:Future):Void {}
}
#end
