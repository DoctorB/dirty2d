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
import kha.Rectangle;

class Layer {

	/** The name of this layer */
	public var name(default, null):String;

	/** The width of this layer in tiles */
	public var width(default, null):Int;

	/** The height of this layer in tiles */
	public var height(default, null):Int;

	/** The opacity of an layer */
	public var opacity(default, null):Float;

	/** Is the layer visible? */
	public var visible(default, null):Bool;

	/** All tiles which this Layer contains */
	public var tiles(default, null):Array<Tile>;

	/** The parent TiledMap */
	public var parent(default, null):TiledMap;

	private function new(parent:TiledMap, name:String, width:Int, height:Int,
			opacity:Float, visible:Bool, tiles:Array<Int>) {
		this.parent = parent;
		this.name = name;
		this.width = width;
		this.height = height;
		this.opacity = opacity;
		this.visible = visible;

		this.tiles = new Array<Tile>();

		for(gid in tiles) {
			this.tiles.push(Tile.fromGID(gid, this));
		}
	}

	/**
	 * This method generates a new Layer from the given Xml code
	 * @param xml The given xml code
	 * @param
	 * @return A new layer
	 */
	public static function fromGenericXml(xml:Xml, parent:TiledMap):Layer {
		var name:String = xml.get("name");
		var width:Int = Std.parseInt(xml.get("width"));
		var height:Int = Std.parseInt(xml.get("height"));
		var opacity:Float = Std.parseFloat(xml.get("opacity") != null ?
			xml.get("opacity") : "1.0");
		var visible:Bool = xml.get("visible") == null ?
			true : Std.parseInt(xml.get("visible")) == 1 ?
				true : false;

		var tileGIDs:Array<Int> = new Array<Int>();

		for (child in xml) {
			if(Helper.isValidElement(child)) {
				if (child.nodeName == "data") {
					var encoding:String = "";
					if (child.exists("encoding")){
						encoding = child.get("encoding");
					}
					var chunk:String = "";
					switch(encoding){
						case "base64":
							throw "dirty2d: base64 not supported at the moment";
						case "csv":
							chunk = child.firstChild().nodeValue;
							tileGIDs = csvToArray(chunk);
						default:
							for (tile in child) {
								if (Helper.isValidElement(tile)) {
									var gid = Std.parseInt(tile.get("gid"));
									tileGIDs.push(gid);
								}
							}
					}
				}
			}
		}

		return new Layer(parent, name, width, height, opacity, visible, tileGIDs);
	}

	/**
	 * This method generates a version of this layer in CSV
	 * @param ?width [OPTIONAL] The number of tiles in width. Default: The layer width.
	 * @return A string which contains CSV
	 */
	public function toCSV(?width:Int):String {
		if(width <= 0 || width == null) {
			width = this.width;
		}

		var counter:Int = 0;
		var csv:String = "";

		for(tile in this.tiles) {
			var tileGID = tile.gid;

			if(counter >= width) {
				// remove the last ","
				csv = csv.substr(0, csv.length - 1);

				// add a new line and reset counter
				csv += '\n';
				counter = 0;
			}

			csv += tileGID;
			csv += ',';

			counter++;
		}

		// remove the last ","
		csv = csv.substr(0, csv.length - 1);

		return csv;
	}

	private static function csvToArray(input:String):Array<Int> {
		var result:Array<Int> = new Array<Int>();
		var rows:Array<String> = StringTools.trim(input).split("\n");
		var row:String;

		for (row in rows) {

			if (row == "") {
				continue;
			}

			var resultRow:Array<Int> = new Array<Int>();
			var entries:Array<String> = row.split(",");
			var entry:String;

			for (entry in entries) {

				if(entry != "") {
					result.push(Std.parseInt(entry));
				}
			}
		}
		return result;
	}
	
	public function render(g: Graphics): Void {
		if (!this.visible || parent == null) return;
		var gidCounter:Int = 0;
		for (y in 0...this.parent.heightInTiles) {
			for (x in 0...this.parent.widthInTiles) {
				var nextGID = this.tiles[gidCounter].gid;
				if (nextGID != 0) {
					var destx : Float;
					var desty : Float;
					switch (map.orientation) {
						case TiledMapOrientation.Orthogonal:
							destx = x * this.parent.tileWidth;
							desty = y * this.parent.tileHeight;
						case TiledMapOrientation.Isometric:
							destx = (this.parent.totalWidth + x - y - 1) * this.parent.tileWidth * 0.5; //TODO: test
							desty = (y + x) * this.parent.tileHeight * 0.5;
					}

					var tileset : Tileset = this.parent.getTilesetByGID(nextGID);
					var rect : Rectangle = tileset.getTileRectByGID(nextGID);

					if(this.parent.orientation == TiledMapOrientation.Isometric) { //Why?
						destx += this.parent.totalWidth/2;
					}
					
					g.drawScaledSubImage(tileset.image.texture, rect.x, rect.y, rect.width, rect.height, destx, desty, this.parent.tileWidth, this.parent.tileHeight);
					
					// draw
					//painter.drawImage2(tileset.image.texture, rect.x, rect.y, rect.width, rect.height, destx, desty, map.tileWidth, map.tileHeight);
					//bitmapData.copyPixels(tileset.image.texture, rect, point, null, null, true);
				}
				
				gidCounter++;
			}
		}
	}

}
