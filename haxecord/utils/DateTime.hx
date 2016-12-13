package haxecord.utils;

/**
 * ...
 * @author Billyoyo
 */
class DateTime
{
	
	public var year:Int;
	public var month:Int;
	public var day:Int;
	public var hour:Int;
	public var minute:Int;
	public var second:Float;
	public var timezone:Int;
	
	public function new(year:Int, month:Int, day:Int, hour:Int, minute:Int, second:Float, ?timezone:Int) 
	{
		this.year = year;
		this.month = month;
		this.day = day;
		this.hour = hour;
		this.minute = minute;
		this.second = second;
		if (timezone == null) timezone = 0;
		this.timezone = timezone;
	}
	
	public function isOlderThan(other:DateTime):Bool
	{
		return  (year < other.year) ||
				(month < other.month) ||
				(day < other.day) ||
				(hour < other.hour) ||
				(minute < other.minute) ||
				(second < other.second);
	}
	
	public function isYoungerThan(other:DateTime):Bool
	{
		return other.isOlderThan(this);
	}
	
	public function getTotalDays():Int
	{
		var y:Int = year - (month <= 2 ? 1 : 0);
		var era:Int = Std.int((y >= 0 ? y : y - 399) / 400);
		var yoe:Int = (y - (era * 400));
		var doy:Int = Std.int((153 * (month + (month > 2 ? -3 : 9)) + 2) / 5) + day - 1;
		var doe:Int = yoe * 365 + Std.int(yoe / 4) - Std.int(yoe / 100) + doy;
		return era * 146097 + doe - 719468;
	}
	
	public static function now():DateTime
	{
		return DateTime.fromFloat(Sys.time());
	}
	
	// formatted 2015-04-26T06:26:56.936000+00:00
	public static function fromString(datetime:String):DateTime
	{
		var dateTimeSplit:Array<String> = datetime.split("T");
		var dateSplit:Array<String> = dateTimeSplit[0].split("-");
		var timeTimezoneSplit:Array<String> = dateTimeSplit[1].split("+");
		var timeSplit:Array<String> = timeTimezoneSplit[0].split(":");
		var timezoneSplit:Array<String> = timeTimezoneSplit[1].split(":");
		
		return new DateTime(
			Std.parseInt(dateSplit[0]),
			Std.parseInt(dateSplit[1]),
			Std.parseInt(dateSplit[2]),
			Std.parseInt(timeSplit[0]),
			Std.parseInt(timeSplit[1]),
			Std.parseFloat(timeSplit[2]),
			(Std.parseInt(timezoneSplit[0])*60) + Std.parseInt(timezoneSplit[1])
		);
	}
	
	// time is time since epoch
	public static function fromFloat(time:Float, ?timezone:Int, ?epoch:Int):DateTime
	{
		if (epoch == null) epoch = 719468;
		var days:Int = Std.int(time / 86400);
		
		time = time - (days * 86400);
		var hours:Int = Std.int(time / 3600);
		time = time - (hours * 3600);
		var minutes:Int = Std.int(time / 60);
		
		return DateTime.fromDays(days + epoch, hours, minutes, time - (minutes * 60), timezone);
	}
	
	public static function fromDays(days:Int, ?hours:Int, ?minutes:Int, ?seconds:Float, ?timezone:Int):DateTime
	{
		var era:Int = Std.int((days >= 0 ? days : days - 146096) / 146097);
		var doe:Int = days - (era * 146097);
		var yoe:Int = Std.int((doe - Std.int(doe / 1460) + Std.int(doe / 36524) - Std.int(doe / 146096)) / 365);
		var y:Int = Std.int(yoe) + (era * 400);
		var doy = doe - (365 * yoe + Std.int(yoe / 4) - Std.int(yoe / 100));
		var mp:Int = Std.int((5 * doy + 2) / 153);
		var d:Int = doy - Std.int((153 * mp + 2) / 5) + 1;
		var m:Int = mp + (mp < 10 ? 3 : -9);
		
		return new DateTime(y + (m <= 2 ? 1 : 0), m, d, hours, minutes, seconds, timezone);
	}
	
	private function fixZeroes(n:Int):String
	{
		var s:String = Std.string(n);
		if (s.length < 2) s = "0" + s;
		return s;
	}
	
	private function formatTimezone()
	{
		var hours:Int = Std.int(timezone / 60);
		var minutes:Int = timezone - (hours * 60);
		return '${fixZeroes(hours)}:${fixZeroes(minutes)}';
	}
	
	public function toString()
	{
		return '$year-${fixZeroes(month)}-${fixZeroes(day)}T${fixZeroes(hour)}:${fixZeroes(minute)}:${second}+${formatTimezone()}';
	}
}