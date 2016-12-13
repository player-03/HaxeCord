package tests.async;
import haxecord.async.EventLoop;
import haxecord.async.Future;
import tests.async.resources.ExampleInfiniteAsyncEvent;

/**
 * ...
 * @author Billyoyo
 */
class FutureTimeoutTest
{

	public static function main()
	{
		var loop:EventLoop = new EventLoop();
		
		var future:Future = new Future(loop, new ExampleInfiniteAsyncEvent(), 2);
		
		loop.addFuture(future);
		loop.run(); // [after 2 seconds] will print "future was cancelled"
	}
	
}