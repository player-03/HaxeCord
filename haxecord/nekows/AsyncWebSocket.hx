package haxecord.nekows;
import haxecord.async.AsyncEvent;
import haxecord.async.Cancel;
import haxecord.async.Future;
import haxecord.http.URL;
import haxecord.nekows.SimpleWebSocket;

/**
 * ...
 * @author Billyoyo
 */
class AsyncWebSocket extends SimpleWebSocket implements AsyncEvent
{
	private var timeperiod:Float;
	private var lastTime:Float;
	
	public function new(url:URL, ?origin:String, ?timeperiod:Float)
	{
		super(url, origin);
		
		if (timeperiod == null) timeperiod = 0;
		this.timeperiod = timeperiod;
		lastTime = Sys.cpuTime();
	}
	
	public function asyncCheck(future:Future):Bool {
		if (!socketConnected) return true;
		
		if (future.loop.time() - lastTime > timeperiod)
		{
			update(true);
		} else {
			update(false);
		}
		return false;
	}
	
	public function asyncCallback():Void {
		if (socketConnected) disconnect();
	}
	
	public function asyncStart(future:Future):Void {
		connect();
	}
	public function asyncCancel(reason:Cancel):Void {
		disconnect();
	}
	public function asyncSetup(future:Future):Void {}
	
}