package tests.async.resources;
import haxecord.async.Future;
import haxecord.async.FutureFactory;
import haxecord.async.EventLoop;

/**
 * ...
 * @author Billyoyo
 */
class ExampleFutureFactory implements FutureFactory
{
	private var boundFuture:Future = null;
	private var loop:EventLoop;
	
	public function new(loop:EventLoop)
	{
		this.loop = loop;
	}
	
	public function sayHello():Future
	{
		return new Future(loop, new ExampleAsyncEvent(10, "hello"), null, boundFuture, this);
	}
	
	public function sayGoodbye():Future
	{
		return new Future(loop, new ExampleAsyncEvent(5, "goodbye"), null, boundFuture, this);
	}
	
	public function bindFuture(future:Future)
	{
		this.boundFuture = future;
	}
}