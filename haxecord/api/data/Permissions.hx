package haxecord.api.data;

/**
 * ...
 * @author Billyoyo
 */
class Permissions
{
	public var raw(default, null):Int;

	public function new(permissions:Int) 
	{
		this.raw = permissions;
	}
	
}