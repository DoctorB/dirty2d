package dirty2d;

class Common
{

	public function new() {
	}

	/** This method checks if the given Xml element is really a Xml element! */
	public static function isValidElement(element:Xml):Bool {
		if (element == null) return false;
		return element.nodeType == XmlType.Element;
	}

}