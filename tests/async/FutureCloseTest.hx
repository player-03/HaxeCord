package tests.async;
import haxecord.async.EventLoop;
import haxecord.async.Future;
import tests.async.resources.ExampleClosureAsyncEvent;

/**
 * ...
 * @author Billyoyo
 */
class FutureCloseTest
{

	public static function main()
	{
		var loop:EventLoop = new EventLoop();
		
		var future1:Future = new Future(loop, new ExampleClosureAsyncEvent(20, "hello world 1"));
		var future2:Future = new Future(loop, new ExampleClosureAsyncEvent(10, "hello world 2"));
		
		loop.addFuture(future1);
		loop.addFuture(future2);
		
		loop.run();
		// will print "hello world 2" and "future was cancelled"
	}
	
	
}