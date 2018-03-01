package haxecord.http;
import haxe.Http;
import haxe.io.BytesOutput;
import haxecord.async.AsyncEvent;
import haxecord.async.Cancel;
import haxecord.async.Future;

#if cpp
import cpp.vm.Thread;
#elseif neko
import neko.vm.Thread;
#end

#if sys
/**
 * ...
 * @author Billyoyo
 */
class HTTPRequest implements AsyncEvent
{
	
	private var http:Http;
	private var method:String;
	private var result:Null<Result>;
	private var onComplete:String -> Void;
	private var onError:String -> Void;
	
	public function new(http:Http, ?method:String, ?onComplete:String -> Void, ?onError:String -> Void) 
	{
		this.http = http;
		this.method = method;
		this.onComplete = onComplete;
		this.onError = onError;
	}
	
	@:access(haxe.Http)
	public function asyncStart(future:Future) 
	{
		Thread.create(function()
		{
			var output:BytesOutput = new BytesOutput();
			http.onError = function(message:String)
			{
				#if neko
				http.responseData = neko.Lib.stringReference(output.getBytes());
				#else
				http.responseData = output.getBytes().toString();
				#end
				result = ERROR(message + ": " + http.responseData);
			}
			http.onStatus = function(status:Int) {}
			http.onData = function(data:String) {}
			
			if (future.timeout != null) http.cnxTimeout = future.timeout;
			
			http.customRequest(method == "POST", output, null, method);
			
			if (result == null && http != null) {
				#if neko
				http.responseData = neko.Lib.stringReference(output.getBytes());
				#else
				http.responseData = output.getBytes().toString();
				#end
				result = COMPLETE(http.responseData);
			}
		});
	}
	
	public function asyncCancel(reason:Cancel) 
	{
		http = null;
		result = null;
	}
	
	public function asyncCheck(future:Future):Bool 
	{
		return result != null;
	}
	
	public function asyncCallback()
	{
		switch (result) {
			case COMPLETE(content):
				if (onComplete != null) onComplete(content);
			case ERROR(message):
				if (onError != null) onError(message);
			default:
		}
	}
	
	public function asyncSetup(future:Future):Void {}
}

private enum Result
{
	COMPLETE(content:String);
	ERROR(message:String);
}

#end
