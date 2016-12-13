package tests.async;
import haxecord.async.AsyncEvent;
import haxecord.async.Cancel;
import haxecord.async.EventLoop;
import haxecord.async.Future;
import tests.async.resources.ExampleAsyncEvent;
import tests.async.resources.ExampleClosureAsyncEvent;

/**
 * ...
 * @author Billyoyo
 */
class FutureTest
{

	public static function main()
	{
		var loop:EventLoop = new EventLoop();
		
		var future1:Future = new Future(loop, new ExampleAsyncEvent(10, "hello world"));
		
		loop.addFuture(future1);
		loop.run();  // will print "hello world"
		
		// alternative:
		var future2:Future = new Future(loop, new ExampleAsyncEvent(10, "hello world"));
		for (i in 0...10)
		{
			future2.yield();
		}
		// will print "hello world"
	}
	
	
	
}