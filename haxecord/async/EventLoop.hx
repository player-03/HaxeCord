package haxecord.async;

import haxe.Timer;
import haxecord.async.cancels.ClosureCancel;

/**
 * ...
 * @author Billyoyo
 */
class EventLoop
{
	
	private var futures:Array<Future> = new Array<Future>();
	private var timer:Timer;
	
	public static function chain(futures:Array<Future>):Future {
		var lastFuture:Future = null;
		for (future in futures) {
			if (lastFuture != null) lastFuture.setChild(future);
			lastFuture = future;
		}
		return lastFuture;
	}
	
	public function new(?loopTime:Float = 0.05) 
	{
		timer = new Timer(loopTime);
		timer.run = update;
	}
	
	public function close()
	{
		var cancel:ClosureCancel = new ClosureCancel();
		for (future in futures)
		{
			future.cancel(cancel);
		}
		timer.stop();
	}

	public function time():Float
	{
		return Sys.time();
	}
	
	public function addFuture(future:Future)
	{
		futures.insert(futures.length, future);
		future.start();
	}
	
	public function addTask(event:AsyncEvent, ?timeout:Float)
	{
		var future:Future = createTask(event, timeout);
		addFuture(future);
		return future;
	}
	
	public function createTask(event:AsyncEvent, ?timeout:Float)
	{
		return new Future(this, event, timeout);
	}
	
	private function update()
	{
		var i:Int = 0;
		while (i < futures.length) {
			var future:Future = futures[i];
			future.yield();
			if (future.isDone()) {
				futures.remove(future);
				i--;
			}
			i++;
		}
	}
	
}