package haxecord.async.events;
import haxe.macro.Type;
import haxecord.async.AsyncEvent;
import haxecord.async.EventLoop;
import haxecord.async.Future;

/**
 * ...
 * @author Billyoyo
 */
class Delay implements AsyncEvent
{
	private var callback:Void->Void;
	private var delay:Float;
	private var end:Float;

	public function new(delay:Float, callback:Void->Void) 
	{
		this.callback = callback;
		this.delay = delay;
	}
	
	public function asyncCallback()
	{
		callback();
	}
	
	public function asyncCheck(future:Future)
	{
		if (future.loop.time() >= end) 
		{
			return true;
		}
		return false;
	}
	
	public function asyncStart(future:Future)
	{
		end = future.loop.time() + delay;
	}
	
	public function asyncCancel(reason:Cancel) {}
	public function asyncSetup(future:Future) {}
	
	
}