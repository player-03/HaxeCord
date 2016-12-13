package haxecord.async;
import haxecord.async.cancels.ClosureCancel;
/**
 * ...
 * @author Billyoyo
 */
class EventLoop
{
	
	private var futures:Array<Future> = new Array<Future>();
	private var limiter:Float = 0;
	
	public static function chain(futures:Array<Future>):Future {
		var lastFuture:Future = null;
		for (future in futures) {
			if (lastFuture != null) lastFuture.setChild(future);
			lastFuture = future;
		}
		return lastFuture;
	}
	
	public function new(?limiter:Float) 
	{
		if (limiter != null) {
			this.limiter = limiter;
		}
	}
	
	public function close()
	{
		var cancel:ClosureCancel = new ClosureCancel();
		for (future in futures)
		{
			future.cancel(cancel);
		}
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
	
	public function addTask(event:AsyncEvent, ?timeout:Float) {
		var future:Future = createTask(event, timeout);
		addFuture(future);
		return future;
	}
	
	public function createTask(event:AsyncEvent, ?timeout:Float) {
		return new Future(this, event, timeout);
		
	}
	
	public function yield(?future:Future) {
		if (future != null) {
			addFuture(future);
		}
		
		
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
	
	private function runWithLimiter()
	{
		while (futures.length > 0)
		{
			yield();
			Sys.sleep(limiter);
		}
	}
	
	private function runWithoutLimiter()
	{
		while (futures.length > 0)
		{
			yield();
			
		}
	}
	
	public function run()
	{
		if (limiter > 0) {
			runWithLimiter();
		} else {
			runWithoutLimiter();
		}
		
	}
	
}