package dirty2d;

class Common
{

	public function new() {
	}

	/** This method checks if the given Xml element is really a Xml element! */
	public static function isValidElement(element:Xml):Bool {
		if (element == null) return false;
		return Std.string(element.nodeType) == "0";
	}

	public static function clamp(value:Float, min:Float, max:Float) : Float {
    if (value < min)
        return min;
    else if (value > max)
        return max;
    else
        return value;
  }
	
}