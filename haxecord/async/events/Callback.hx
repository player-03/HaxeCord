package haxecord.async.events;
import haxecord.async.AsyncEvent;

/**
 * ...
 * @author Billyoyo
 */
class Callback implements AsyncEvent
{
	private var callback:Void->Void;
	public function new(callback:Void->Void) 
	{
		this.callback = callback;
	}
	
	public function asyncCheck(future:Future):Bool {return true;}
	public function asyncCallback():Void { callback(); }
	public function asyncStart(future:Future):Void {}
	public function asyncCancel(reason:Cancel):Void {}
	public function asyncSetup(future:Future):Void {}
}