package tests.async.resources;
import haxecord.async.AsyncEvent;
import haxecord.async.Cancel;
import haxecord.async.Future;

/**
 * ...
 * @author Billyoyo
 */
class ExampleInfiniteAsyncEvent implements AsyncEvent
{

	public function new() { }
	
	public function asyncCheck(future:Future):Bool 
	{
		return false;
	}
	
	public function asyncCallback():Void 
	{
		// this event will never be finished
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