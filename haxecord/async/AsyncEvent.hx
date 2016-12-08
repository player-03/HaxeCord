package haxecord.async;

/**
 * @author Billyoyo
 */
interface AsyncEvent 
{
	public function asyncCheck(future:Future):Bool;
	public function asyncCallback():Void;
	public function asyncStart(future:Future):Void;
	public function asyncCancel(reason:Cancel):Void;
	public function asyncSetup(future:Future):Void;
	
}