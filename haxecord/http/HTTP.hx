package haxecord.http;
import haxe.io.Bytes;
import haxe.web.Request;
import haxecord.async.EventLoop;
import haxecord.async.Future;
import haxecord.async.FutureFactory;
import haxe.Json;
import haxecord.http.HTTPException;
import haxecord.http.HTTPRequest;
import haxecord.http.URL;
import haxecord.http.HTTP.OptionalRequestArgs;

typedef OptionalRequestArgs = {
	@:optional var headers:Map<String, String>;
	@:optional var text:String;
	@:optional var json:Dynamic;
	@:optional var data:Bytes;
	@:optional var image:Bytes;
	@:optional var imageExtension:String;
	@:optional var onComplete:HTTPRequest->HTTPResponse-> Void;
	@:optional var onError:HTTPRequest->HTTPException->Void;
	@:optional var timeout:Float;
}


/**
 * ...
 * @author Billyoyo
 */
class HTTP implements FutureFactory
{
	private var validRequestArgs:Array<String> = [
		"headers", "text", "json", "data", "image", "imageExtension", "onComplete", "onError", "timeout"
	];
	
	private var boundFuture:Future = null;
	public var loop:EventLoop;
	
	public function new(?loop:EventLoop) 
	{
		this.loop = loop;
	}
	
	private function getRequest(method:String, url:String, ?options:OptionalRequestArgs)
	{
		var request:HTTPRequest = new HTTPRequest(new URL(url));
		request.setMethod(method);
		if (options.headers != null) request.setHeaders(options.headers);
		if (options.json != null) {
			request.setContent(Json.stringify(options.json));
			request.setContentType("application/json");
		}
		else if (options.text != null) {
			request.setContent(options.text);
			request.setContentType("text/html");
		}
		else if (options.image != null) {
			request.setContent(options.image);
			request.setContentType("image/" + options.imageExtension);
		}
		else if (options.data != null) {
			request.setContent(options.data);
		}
		request.setCompleteCallback(options.onComplete);
		request.setErrorCallback(options.onError);
		return request;
	}
	
	
	public function request(method:String, url:String, ?options:OptionalRequestArgs):Future
	{
		if (loop == null) throw new HTTPException(null, "loop not set, cannot use async requests", 0);
		return new Future(loop, getRequest(method, url, options), options.timeout, boundFuture, this);
	}
	
	public function get(url:String, ?options:OptionalRequestArgs, ?sync:Bool):Dynamic
	{
		if (sync == null || sync == false) return request("GET", url, options);
		else return syncRequest("GET", url, options);
	}
	
	public function post(url:String, ?options:OptionalRequestArgs, ?sync:Bool):Dynamic
	{
		if (sync == null || sync == false) return request("POST", url, options);
		else return syncRequest("POST", url, options);
	}
	
	public function patch(url:String, ?options:OptionalRequestArgs, ?sync:Bool):Dynamic
	{
		if (sync == null || sync == false) return request("PATCH", url, options);
		else return syncRequest("PATCH", url, options);
	}
	
	public function put(url:String, ?options:OptionalRequestArgs, ?sync:Bool):Dynamic
	{
		if (sync == null || sync == false) return request("PUT", url, options);
		else return syncRequest("PUT", url, options);
	}
	
	public function delete(url:String, ?options:OptionalRequestArgs, ?sync:Bool):Dynamic
	{
		if (sync == null || sync == false) return request("DELETE", url, options);
		else return syncRequest("DELETE", url, options);
	}
	
	public function syncRequest(method:String, url:String, ?options:OptionalRequestArgs):HTTPResponse
	{
		var request:HTTPRequest = getRequest(method, url, options);
		var response:HTTPResponse = null;
		if (options.onComplete == null) request.setCompleteCallback(function(req:HTTPRequest, resp:HTTPResponse) { response = resp; });
		request.await();
		return response;
	}
	
	public function bindFuture(future:Future):Void
	{
		this.boundFuture = future;
	}
	
}