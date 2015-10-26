// Copyright (C) 2013 Christopher "Kasoki" Kaster
//
// This file is part of "openfl-tiled". <http://github.com/Kasoki/openfl-tiled>
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

package dirty2d;

import kha.graphics2.Graphics;
import haxe.io.Path;
import kha.Rectangle;

class ImageLayer {

	public var tiledMap(default, null):TiledMap;
	public var name(default, null):String;
	public var opacity(default, null):Float;
	public var visible(default, null):Bool;
	
	public var x(default, null): Int;
	public var y(default, null): Int;

	public var properties(default, null):Map<String, String>;
	public var image(default, null):TilesetImage;

	private function new(tiledMap:TiledMap, name:String, opacity:Float, visible:Bool, properties:Map<String, String>, image:TilesetImage, x: Int, y: Int) {
		this.tiledMap = tiledMap;
		this.name = name;
		this.opacity = opacity;
		this.visible = visible;
		this.properties = properties;
		this.image = image;
		this.x = x;
		this.y = y;
	}

	public static function fromGenericXml(tiledMap:TiledMap, xml:Xml):ImageLayer {
		var name:String = xml.get("name");
		var opacity:Float = xml.exists("opacity") ? Std.parseFloat(xml.get("opacity")) : 1.0;
		var visible:Bool = xml.exists("visible") ? Std.parseInt("visible") == 1 : false;

		/*
		 <imagelayer name="image_1" x="10" y="10">
			<image source="purple.png"/>
		 </imagelayer>
		*/
		
		// Added
		var x: Int = xml.exists("x") ? Std.parseInt("x") : 0;
		var y: Int = xml.exists("y") ? Std.parseInt("y") : 0;
		
		var properties = new Map<String, String>();
		var image:TilesetImage = null;

		for(child in xml.elements()) {
			if(Common.isValidElement(child)) {
				if(child.nodeName == "properties") {
					for(property in child) {
						if(Common.isValidElement(property)) {
							properties.set(property.get("name"), property.get("value"));
						}
					}
				}
			}

			if (child.nodeName == "image") {
				image = new TilesetImage(child.get("source"), child.get("trans"));
			}
		}

		return new ImageLayer(tiledMap, name, opacity, visible, properties, image, x, y);
	}
	
	public function render(g: Graphics, xleft: Int, ytop: Int, width: Int, height: Int): Void {
		if (this.image == null || !this.visible) return;
		// TODO: check boundary conditions
		g.drawImage(this.image.texture, 0, 0);
	}
	
	public function collides(rect: Rectangle) : Bool {
		if (this.image == null || !this.visible) return false;
		
		return false;
	}
	
}