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

import kha.Color;
import kha.Loader;
import kha.graphics2.Graphics;
import kha.math.Vector2;
import kha.math.Vector2i;
import kha.Rectangle;


@:expose
class TiledMap {

	/** The path of the map file */
	public var path(default, null):String;

	/** The map width in tiles */
	public var widthInTiles(default, null):Int;

	/** The map height in tiles */
	public var heightInTiles(default, null):Int;

	/** The map width in pixels */
	public var totalWidth(get_totalWidth, null):Int;

	/** The map height in pixels */
	public var totalHeight(get_totalHeight, null):Int;

	/** TILED orientation: Orthogonal or Isometric */
	public var orientation(default, null):TiledMapOrientation;

	/** The tile width */
	public var tileWidth(default, null):Int;

	/** The tile height */
	public var tileHeight(default, null):Int;

	/** The background color of the map */
	public var backgroundColor(default, null):UInt;

	/** All tilesets the map is using */
	public var tilesets(default, null):Array<Tileset>;

	/** Contains all layers from this map */
	public var layers(default, null):Array<Layer>;

	/** All objectgroups */
	public var objectGroups(default, null):Array<TiledObjectGroup>;

	/** All image layers **/
	public var imageLayers(default, null):Array<ImageLayer>;

	/** All map properties */
	public var properties(default, null):Map<String, String>;

	public var backgroundColorSet(default, null):Bool = false;

	private function new(path:String) {
		this.path = path;
		var xml = Loader.the.getBlob(path).toString();
		parseXML(xml);
	}

	/**
	 * Creates a new TiledMap from Assets
	 * @param path The path to your asset
	 * @param render Should openfl-tiled render the map?
	 * @return A TiledMap object
	 */
	public static function fromAssets(path:String):TiledMap {
		return new TiledMap(path);
	}

	private function parseXML(xml:String) {
		
		trace(xml);
		var xml = Xml.parse(xml).firstElement();

		this.widthInTiles = Std.parseInt(xml.get("width"));
		this.heightInTiles = Std.parseInt(xml.get("height"));
		this.orientation = xml.get("orientation") == "orthogonal" ? TiledMapOrientation.Orthogonal : TiledMapOrientation.Isometric;
		this.tileWidth = Std.parseInt(xml.get("tilewidth"));
		this.tileHeight = Std.parseInt(xml.get("tileheight"));
		this.tilesets = new Array<Tileset>();
		this.layers = new Array<Layer>();
		this.objectGroups = new Array<TiledObjectGroup>();
		this.imageLayers = new Array<ImageLayer>();
		this.properties = new Map<String, String>();

		
		
		// get background color
		var backgroundColor:String = xml.get("backgroundcolor");

		// if the element isn't set choose white
		if(backgroundColor != null) {
			this.backgroundColorSet = true;

			// replace # with 0xff to match ARGB
			backgroundColor = StringTools.replace(backgroundColor, "#", "0xff");

			this.backgroundColor = Std.parseInt(backgroundColor);
		} else {
			this.backgroundColor = 0x00000000;
		}

		for (child in xml) {
			if(Common.isValidElement(child)) {
				trace("xml child.nodename: " + child.nodeName);
				
				if (child.nodeName == "tileset") {
					var tileset:Tileset = null;

					if (child.get("source") != null) {
						tileset = Tileset.fromGenericXml(this, Loader.the.getBlob(child.get("source")).toString());
					} else {
						tileset = Tileset.fromGenericXml(this, child.toString());
					}

					tileset.setFirstGID(Std.parseInt(child.get("firstgid")));

					this.tilesets.push(tileset);
				} else if (child.nodeName == "properties") {
					for (property in child) {
						if (!Common.isValidElement(property))
							continue;
						properties.set(property.get("name"), property.get("value"));
					}
				} else if (child.nodeName == "layer") {
					var layer:Layer = Layer.fromGenericXml(child, this);

					this.layers.push(layer);
				} else if (child.nodeName == "objectgroup") {
					var objectGroup = TiledObjectGroup.fromGenericXml(child);

					this.objectGroups.push(objectGroup);
				} else if (child.nodeName == "imagelayer") {
					var imageLayer = ImageLayer.fromGenericXml(this, child);

					this.imageLayers.push(imageLayer);
				}
			}
		}
	}

	/**
	 * Returns the Tileset which contains the given GID.
	 * @return The tileset which contains the given GID, or if it doesn't exist "null"
	 */
	public function getTilesetByGID(gid:Int):Tileset {
		var tileset:Tileset = null;

		for(t in this.tilesets) {
			if(gid >= t.firstGID) {
				tileset = t;
			}
		}

		return tileset;
	}

	/**
	 * Returns the total Width of the map
	 * @return Map width in pixels
	 */
	private function get_totalWidth():Int {
		return this.widthInTiles * this.tileWidth;
	}

	/**
	 * Returns the total Height of the map
	 * @return Map height in pixels
	 */
	private function get_totalHeight():Int {
		return this.heightInTiles * this.tileHeight;
	}

	/**
	 * Returns the layer with the given name.
	 * @param name The name of the layer
	 * @return The searched layer, null if there is no such layer.
	 */
	public function getLayerByName(name:String):Layer {
		for(layer in this.layers) {
			if(layer.name == name) {
				return layer;
			}
		}

		return null;
	}

	/**
	 * Returns the object group with the given name.
	 * @param name The name of the object group
	 * @return The searched object group, null if there is no such object group.
	 */
	public function getObjectGroupByName(name:String):TiledObjectGroup {
		for(objectGroup in this.objectGroups) {
			if(objectGroup.name == name) {
				return objectGroup;
			}
		}

		return null;
	}

	 /**
	  * Returns an object in a given object group
	  * @param name The name of the object
	  * @param inObjectGroup The object group which contains this object.
	  * @return An TiledObject, null if there is no such object.
	  */
	public function getObjectByName(name:String, inObjectGroup:TiledObjectGroup):TiledObject {
		for(object in inObjectGroup) {
			if(object.name == name) {
				return object;
			}
		}

		return null;
	}

	public function render(g: Graphics, xleft: Int, ytop: Int, width: Int, height: Int): Void {
		g.color = Color.White;
		
		trace("tiledMap_render xleft: " +  xleft +  " ytop: " + ytop + " width:" + width + " height:" + height);
		trace("this.layers: " + this.layers.length);
		
		for (layer in this.layers) {
			layer.render(g, xleft, ytop, width, height);
		}
		
		/*
		for (imageLayer in this.imageLayers) {
			imageLayer.render(g, xleft, ytop, width, height);
		}
		*/
	}
	
	public function collides(sprite: Sprite, withWhat: ColliderObject): Bool {
		var rect = sprite.collisionRect();
		if (withWhat == ColliderObject.ALL) {
			
		} else if (withWhat == ColliderObject.IMAGELAYER) {
			
		} else if (withWhat == ColliderObject.LAYER) {
			
		} else if (withWhat == ColliderObject.TILEDOBJECT) {
			
		}
		
		return false;
	}
	
	public function collidesPoint(point: Vector2, withWhat: ColliderObject): Bool {
		if (withWhat == ColliderObject.ALL) {
			
		} else if (withWhat == ColliderObject.IMAGELAYER) {
			
		} else if (withWhat == ColliderObject.LAYER) {
			
		} else if (withWhat == ColliderObject.TILEDOBJECT) {
			
		}
		return false;
	}
	
	/*
	public function index(xpos: Float, ypos: Float): Vector2i {
		var xtile: Int = Std.int(xpos / tileset.TILE_WIDTH);
		var ytile: Int = Std.int(ypos / tileset.TILE_HEIGHT);
		return new Vector2i(xtile, ytile);
	}
	
	public function get(x: Int, y: Int): Int {
		return map[x][y];
	}
	
	public function set(x: Int, y: Int, value: Int) {
		map[x][y] = value;
	}
	
	private static function mod(a: Int, b: Int): Int {
		var r = a % b;
		return r < 0 ? r + b : r;
	}
		
	public function collidesPoint(point: Vector2): Bool {
		var xtile: Int = Std.int(point.x / tileset.TILE_WIDTH);
		var ytile: Int = Std.int(point.y / tileset.TILE_HEIGHT);
		return tileset.tile(map[xtile][ytile]).collides;
	}
	
	public function collides(sprite: Sprite): Bool {
		var rect = sprite.collisionRect();
		if (rect.x <= 0 || rect.y <= 0 || rect.x + rect.width >= getWidth() * tileset.TILE_WIDTH || rect.y + rect.height >= getHeight() * tileset.TILE_HEIGHT) return true;
		var delta = 0.001;
		var xtilestart : Int = Std.int((rect.x + delta) / tileset.TILE_WIDTH);
		var xtileend : Int = Std.int((rect.x + rect.width - delta) / tileset.TILE_WIDTH);
		var ytilestart : Int = Std.int((rect.y + delta) / tileset.TILE_HEIGHT);
		var ytileend : Int = Std.int((rect.y + rect.height - delta) / tileset.TILE_HEIGHT);
		for (ytile in ytilestart...ytileend + 1) {
			for (xtile in xtilestart...xtileend + 1) {
				collisionRectCache.x = rect.x - xtile * tileset.TILE_WIDTH;
				collisionRectCache.y = rect.y - ytile * tileset.TILE_HEIGHT;
				collisionRectCache.width = rect.width;
				collisionRectCache.height = rect.height;
				if (xtile > 0 && ytile > 0 && xtile < map.length && ytile < map[xtile].length && tileset.tile(map[xtile][ytile]) != null)
					if (tileset.tile(map[xtile][ytile]).collision(collisionRectCache)) return true;
			}
		}
		return false;
	}
	
	function collidesupdown(x1: Int, x2: Int, y: Int, rect: Rectangle): Bool {
		if (y < 0 || y / tileset.TILE_HEIGHT >= levelHeight) return false;
		var xtilestart: Int = Std.int(x1 / tileset.TILE_WIDTH);
		var xtileend: Int = Std.int(x2 / tileset.TILE_WIDTH);
		var ytile: Int = Std.int(y / tileset.TILE_HEIGHT);
		for (xtile in xtilestart...xtileend + 1) {
			collisionRectCache.x = rect.x - xtile * tileset.TILE_WIDTH;
			collisionRectCache.y = rect.y - ytile * tileset.TILE_HEIGHT;
			collisionRectCache.width = rect.width;
			collisionRectCache.height = rect.height;
			if (tileset.tile(map[xtile][ytile]).collision(collisionRectCache)) return true;
		}
		return false;
	}
	
	function collidesrightleft(x: Int, y1: Int, y2: Int, rect: Rectangle): Bool {
		if (x < 0 || x / tileset.TILE_WIDTH >= levelWidth) return true;
		var ytilestart: Int = Std.int(y1 / tileset.TILE_HEIGHT);
		var ytileend: Int = Std.int(y2 / tileset.TILE_HEIGHT);
		var xtile: Int = Std.int(x / tileset.TILE_WIDTH);
		for (ytile in ytilestart...ytileend + 1) {
			if (ytile < 0 || ytile >= levelHeight) continue;
			collisionRectCache.x = rect.x - xtile * tileset.TILE_WIDTH;
			collisionRectCache.y = rect.y - ytile * tileset.TILE_HEIGHT;
			collisionRectCache.width = rect.width;
			collisionRectCache.height = rect.height;
			if (tileset.tile(map[xtile][ytile]).collision(collisionRectCache)) return true;
		}
		return false;
	}
	
	private static function round(value: Float): Int {
		return Math.round(value);
	}
	
	public function collideright(sprite: Sprite): Bool {
		var rect: Rectangle = sprite.collisionRect();
		var collided: Bool = false;
		while (collidesrightleft(Std.int(rect.x + rect.width), round(rect.y + 1), round(rect.y + rect.height - 1), rect)) {
			--sprite.x; // = Math.floor((rect.x + rect.width) / tileset.TILE_WIDTH) * tileset.TILE_WIDTH - rect.width;
			collided = true;
			rect = sprite.collisionRect();
		}
		return collided;
	}
	
	public function collideleft(sprite: Sprite): Bool {
		var rect: Rectangle = sprite.collisionRect();
		var collided: Bool = false;
		while (collidesrightleft(Std.int(rect.x), round(rect.y + 1), round(rect.y + rect.height - 1), rect)) {
			++sprite.x; // = (Math.floor(rect.x / tileset.TILE_WIDTH) + 1) * tileset.TILE_WIDTH;
			collided = true;
			rect = sprite.collisionRect();
		}
		return collided;
	}
	
	public function collidedown(sprite: Sprite): Bool {
		var rect: Rectangle = sprite.collisionRect();
		var collided: Bool = false;
		while (collidesupdown(round(rect.x + 1), round(rect.x + rect.width - 1), Std.int(rect.y + rect.height), rect)) {
			--sprite.y; // = Math.floor((rect.y + rect.height) / tileset.TILE_HEIGHT) * tileset.TILE_HEIGHT - rect.height;
			collided = true;
			rect = sprite.collisionRect();
		}
		return collided;
	}
	
	public function collideup(sprite: Sprite): Bool {
		var rect: Rectangle = sprite.collisionRect();
		var collided: Bool = false;
		while (collidesupdown(round(rect.x + 1), round(rect.x + rect.width - 1), Std.int(rect.y), rect)) {
			++sprite.y; // = ((Math.floor(rect.y / tileset.TILE_HEIGHT) + 1) * tileset.TILE_HEIGHT);
			collided = true;
			rect = sprite.collisionRect();
		}
		return collided;
	}
	*/
}
