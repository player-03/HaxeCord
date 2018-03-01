package haxecord.async;
import haxecord.async.cancels.TimeoutCancel;
import haxecord.async.events.Callback;

/**
 * ...
 * @author Billyoyo
 */
class Future
{

	public var event:AsyncEvent;
	public var loop:EventLoop;
	
	private var parent:Future;
	private var child:Future = null;
	public var factory = null;
	
	private var done:Bool = false;
	private var cancelled:Bool = false;
	private var cancelReason:Cancel = null;
	private var startTime:Float;
	public var timeout(default, null):Null<Float>;
	
	public function new(loop:EventLoop, event:AsyncEvent, ?timeout:Float, ?parent:Future, ?factory:FutureFactory) 
	{
		this.loop = loop;
		this.event = event;
		this.timeout = timeout;
		this.parent = parent;
		this.factory = factory;
		if (parent != null) {
			parent.setChild(this);
		}
		event.asyncSetup(this);
	}
	
	public function setChild(future:Future)
	{
		this.child = future;
	}
	
	public function send()
	{
		if (parent != null) {
			parent.send();
		} else {
			loop.addFuture(this);
		}
	}
	
	public function then(?func:Void->Void, ?timeout:Float):Dynamic
	{
		if (func != null) {
			return new Future(loop, new Callback(func), timeout, this, factory);
		} else {
			if (factory != null) {
				factory.bindFuture(this);
			}
			return factory;
		}
	}
	
	private function finish()
	{
		done = true;
		if (child != null) {
			loop.addFuture(child);
		}
	}
	
	public function yield()
	{
		if (cancelled)
		{
			event.asyncCancel(cancelReason);
			finish();
		}
		else if (event.asyncCheck(this))
		{
			event.asyncCallback();
			finish();
		}
		else if (timeout != null && loop.time() > startTime + timeout)
		{
			cancelled = true;
			event.asyncCancel(new TimeoutCancel());
			finish();
		}
	}
	
	public function start()
	{
		if (timeout != null) startTime = loop.time();
		event.asyncStart(this);
	}
	
	public function cancel(cancel:Cancel)
	{
		cancelled = true;
		cancelReason = cancel;
	}
	
	public function isDone()
	{
		return done;
	}
	
	public function isCancelled()
	{
		return cancel;
	}
}