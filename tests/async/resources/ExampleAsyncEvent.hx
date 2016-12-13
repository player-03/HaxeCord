package tests.async.resources;
import haxecord.async.Cancel;
import haxecord.async.Future;
import haxecord.async.AsyncEvent;

/**
 * ...
 * @author Billyoyo
 */
class ExampleAsyncEvent implements AsyncEvent
{
	private var n:Int;
	private var message:String;
	
	public function new(n:Int, message:String)
	{
		this.n = n;
		this.message = message;
	}
	
	public function asyncCheck(future:Future):Bool 
	{
		// every time the future is yielded, we minus one from n and return whether or not it's zero
		n = n - 1;
		return n <= 0;
	}
	
	public function asyncCallback():Void 
	{
		// we print our message once the future is complete
		trace(message);
	}
	
	// called when the future is added to the eventloop, we don't need to do anything for this future
	public function asyncStart(future:Future):Void {}
	
	// called when the future is cancelled
	public function asyncCancel(reason:Cancel):Void 
	{
		trace("future was cancelled");
	}
	
	// called when the future is created, this is called before asyncStart
	public function asyncSetup(future:Future):Void {}
}