package tests.async;
import haxecord.async.AsyncEvent;
import haxecord.async.Cancel;
import haxecord.async.EventLoop;
import haxecord.async.Future;
import haxecord.async.FutureFactory;
import tests.async.resources.ExampleFutureFactory;

/**
 * ...
 * @author Billyoyo
 */
class FutureFactoryTest
{

	public static function test()
	{
		var loop:EventLoop = new EventLoop();
		var factory:ExampleFutureFactory = new ExampleFutureFactory(loop);
		
		factory.sayHello().then().sayGoodbye().send();
		
		loop.run();
	}
	
}