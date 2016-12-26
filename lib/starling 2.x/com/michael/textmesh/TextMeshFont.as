// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package com.michael.textmesh 
{
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import starling.display.Image;
	import starling.display.MeshBatch;
	import starling.display.Sprite;
	import starling.text.BitmapChar;
	import starling.text.ITextCompositor;
	import starling.text.TextFormat;
	import starling.text.TextOptions;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;
	import starling.utils.Align;
	import starling.utils.StringUtil;
	/**
	 * ...
	 * @author Michael
	 */
	public class TextMeshFont implements ITextCompositor
	{
		/** Use this constant for the <code>fontSize</code> property of the TextField class to 
         *  render the bitmap font in exactly the size it was created. */ 
        public static const NATIVE_SIZE:int = -1;
        
        /** The font name of the embedded minimal bitmap font. Use this e.g. for debug output. */
        public static const MINI:String = "mini";
        
        private static const CHAR_SPACE:int           = 32;
        private static const CHAR_TAB:int             =  9;
        private static const CHAR_NEWLINE:int         = 10;
        private static const CHAR_CARRIAGE_RETURN:int = 13;
        
        private var _texture:Texture;
        private var _chars:Dictionary;
        private var _charsImage:Dictionary;
        private var _name:String;
        private var _size:Number;
        private var _lineHeight:Number;
        private var _baseline:Number;
        private var _offsetX:Number;
        private var _offsetY:Number;
        private var _padding:Number;
        private var _helperImage:Image;

        // helper objects
        private static var sLines:Array = [];
        private static var sDefaultOptions:TextOptions = new TextOptions();
		
		// TextMesh Property
		private var _endIndex:Number;
		private var m_htmlTag:String;
		private var m_actualColor:uint;
		private var m_htmlColor:uint;
        
        /** Creates a bitmap font by parsing an XML file and uses the specified texture. 
         *  If you don't pass any data, the "mini" font will be created. */
		
		public function TextMeshFont(texture:Texture=null, fontXml:XML=null) 
		{
			// if no texture is passed in, we create the minimal, embedded font
            if (texture == null && fontXml == null)
            {
                throw new ArgumentError("Set both of the 'texture' and 'fontXml' arguments to valid objects is Null.");
            }
            else if (texture == null || fontXml == null)
            {
                throw new ArgumentError("Set both of the 'texture' and 'fontXml' arguments to valid objects or leave both of them null.");
            }
            
            _name = "unknown";
            _lineHeight = _size = _baseline = 14;
            _offsetX = _offsetY = _padding = 0.0;
            _texture = texture;
            _chars = new Dictionary();
            _charsImage = new Dictionary();
            _helperImage = new Image(texture);
            
            parseFontXml(fontXml);
		}
		
		/** Disposes the texture of the bitmap font. */
        public function dispose():void
        {
            if (_texture)
                _texture.dispose();
        }
		
		private function parseFontXml(fontXml:XML):void
        {
            var scale:Number = _texture.scale;
            var frame:Rectangle = _texture.frame;
            var frameX:Number = frame ? frame.x : 0;
            var frameY:Number = frame ? frame.y : 0;
            
            _name = StringUtil.clean(fontXml.info.@face);
            _size = parseFloat(fontXml.info.@size) / scale;
            _lineHeight = parseFloat(fontXml.common.@lineHeight) / scale;
            _baseline = parseFloat(fontXml.common.@base) / scale;
            
            if (fontXml.info.@smooth.toString() == "0")
                smoothing = TextureSmoothing.NONE;
            
            if (_size <= 0)
            {
                trace("[Starling] Warning: invalid font size in '" + _name + "' font.");
                _size = (_size == 0.0 ? 16.0 : _size * -1.0);
            }
            
            for each (var charElement:XML in fontXml.chars.char)
            {
                var id:int = parseInt(charElement.@id);
                var xOffset:Number  = parseFloat(charElement.@xoffset)  / scale;
                var yOffset:Number  = parseFloat(charElement.@yoffset)  / scale;
                var xAdvance:Number = parseFloat(charElement.@xadvance) / scale;
                
                var region:Rectangle = new Rectangle();
                region.x = parseFloat(charElement.@x) / scale + frameX;
                region.y = parseFloat(charElement.@y) / scale + frameY;
                region.width  = parseFloat(charElement.@width)  / scale;
                region.height = parseFloat(charElement.@height) / scale;
                
                var texture:Texture = Texture.fromTexture(_texture, region);
                var bitmapChar:TextMeshChar = new TextMeshChar(id, texture, xOffset, yOffset, xAdvance); 
                addChar(id, bitmapChar);
            }
            
            for each (var kerningElement:XML in fontXml.kernings.kerning)
            {
                var first:int  = parseInt(kerningElement.@first);
                var second:int = parseInt(kerningElement.@second);
                var amount:Number = parseFloat(kerningElement.@amount) / scale;
                if (second in _chars) getChar(second).addKerning(first, amount);
            }
        }
        
        /** Returns a single bitmap char with a certain character ID. */
        public function getChar(charID:int):TextMeshChar
        {
            return _chars[charID];
        }
		
		 /** Returns a single bitmap char with a certain character ID. */
        public function getImageChar(charID:int):TextMeshChar
        {
            return _charsImage[charID];
        }
        
        /** Adds a bitmap char with a certain character ID. */
        public function addChar(charID:int, bitmapChar:TextMeshChar):void
        {
            _chars[charID] = bitmapChar;
        }
		
		/** Adds a icon bitmap char with a certain character ID. */
        public function addIconChar(charID:int, bitmapChar:TextMeshChar):void
        {
            _charsImage[charID] = bitmapChar;
        }
        
        /** Returns a vector containing all the character IDs that are contained in this font. */
        public function getCharIDs(out:Vector.<int>=null):Vector.<int>
        {
            if (out == null) out = new <int>[];

            for(var key:* in _chars)
                out[out.length] = int(key);

            return out;
        }

        /** Checks whether a provided string can be displayed with the font. */
        public function hasChars(text:String):Boolean
        {
            if (text == null) return true;

            var charID:int;
            var numChars:int = text.length;

            for (var i:int=0; i<numChars; ++i)
            {
                charID = text.charCodeAt(i);

                if (charID != CHAR_SPACE && charID != CHAR_TAB && charID != CHAR_NEWLINE &&
                    charID != CHAR_CARRIAGE_RETURN && getChar(charID) == null)
                {
                    return false;
                }
            }

            return true;
        }

        /** Creates a sprite that contains a certain text, made up by one image per char. */
        public function createSprite(width:Number, height:Number, text:String,
                                     format:TextFormat, options:TextOptions=null):Sprite
        {
            var charLocations:Vector.<CharLocation> = arrangeChars(width, height, text, format, options);
            var numChars:int = charLocations.length;
            var smoothing:String = this.smoothing;
            var sprite:Sprite = new Sprite();
            
            for (var i:int=0; i<numChars; ++i)
            {
                var charLocation:CharLocation = charLocations[i];
                var char:Image = charLocation.char.createImage();
                char.x = charLocation.x;
                char.y = charLocation.y;
                char.scale = charLocation.scale;
                char.color = format.color;
                char.textureSmoothing = smoothing;
                sprite.addChild(char);
            }
            
            CharLocation.rechargePool();
            return sprite;
        }
        
        /** Draws text into a QuadBatch. */
        public function fillMeshBatch(meshBatch:MeshBatch, width:Number, height:Number, text:String,
                                      format:TextFormat, options:TextOptions=null):void
        {
			actualColor = format.color;
            var charLocations:Vector.<CharLocation> = arrangeChars(
                    width, height, text, format, options);
            var numChars:int = charLocations.length;
            _helperImage.color = format.color;
            
            for (var i:int=0; i<numChars; ++i)
            {
                var charLocation:CharLocation = charLocations[i];
                _helperImage.texture = charLocation.char.texture;
                _helperImage.readjustSize();
                _helperImage.x = charLocation.x;
                _helperImage.y = charLocation.y;
                _helperImage.scale = charLocation.scale;
                _helperImage.color = charLocation.color;
                meshBatch.addMesh(_helperImage);
            }

            CharLocation.rechargePool();
        }

        /** @inheritDoc */
        public function clearMeshBatch(meshBatch:MeshBatch):void
        {
            meshBatch.clear();
        }
        
        /** Arranges the characters of a text inside a rectangle, adhering to the given settings. 
         *  Returns a Vector of CharLocations. */
        private function arrangeChars(width:Number, height:Number, text:String,
                                      format:TextFormat, options:TextOptions):Vector.<CharLocation>
        {
            if (text == null || text.length == 0) return CharLocation.vectorFromPool();
            if (options == null) options = sDefaultOptions;

            var kerning:Boolean = format.kerning;
            var leading:Number = format.leading;
            var hAlign:String = format.horizontalAlign;
            var vAlign:String = format.verticalAlign;
            var fontSize:Number = format.size;
            var autoScale:Boolean = options.autoScale;
            var wordWrap:Boolean = options.wordWrap;

            var finished:Boolean = false;
            var charLocation:CharLocation;
            var numChars:int;
            var containerWidth:Number;
            var containerHeight:Number;
            var scale:Number;
            var finalScale:Number;
            var i:int, j:int;
			
			m_htmlColor = actualColor;

            if (fontSize < 0) fontSize *= -_size;
            
            while (!finished)
            {
                sLines.length = 0;
                scale = fontSize / _size;
                containerWidth  = (width  - 2 * _padding) / scale;
                containerHeight = (height - 2 * _padding) / scale;
                
                if (_lineHeight <= containerHeight)
                {
                    var lastWhiteSpace:int = -1;
                    var lastCharID:int = -1;
                    var currentX:Number = 0;
                    var currentY:Number = 0;
                    var currentLine:Vector.<CharLocation> = CharLocation.vectorFromPool();
                    
                    numChars = text.length;
                    for (i=0; i<numChars; ++i)
                    {
                        var lineFull:Boolean = false;
                        var charID:int = text.charCodeAt(i);
						var char:TextMeshChar;
						if (charID == 60){ // '<'
							var validateTagObject:Object = validateHtmlTag(text, i + 1);
							if (validateTagObject["isValidHtmlTag"]){
								i = endIndex;
								if (validateTagObject["type"] == TagType.Sprite){
									char = getImageChar(validateTagObject["value"]);
								}else if (validateTagObject["type"] == TagType.Color){
									charID = CHAR_SPACE;
									char = getChar(CHAR_SPACE);
								}
							}else{
								char = getChar(charID);
							}
						}else{
							char = getChar(charID);
						}
                        
                        if (charID == CHAR_NEWLINE || charID == CHAR_CARRIAGE_RETURN)
                        {
                            lineFull = true;
                        }
                        else if (char == null)
                        {
                            trace("[Starling] Font: "+ name + " missing character: " + text.charAt(i) + " id: "+ charID);
                        }
                        else
                        {
                            if (charID == CHAR_SPACE || charID == CHAR_TAB)
                                lastWhiteSpace = i;
                            
                            if (kerning)
                                currentX += char.getKerning(lastCharID);
                            
                            charLocation = CharLocation.instanceFromPool(char);
							charLocation.color = m_htmlColor;
							if (char.isIcon){
								finalScale = getChar(84).height / char.height;// 84 = charcter "t"
								charLocation.y = currentY + getChar(84).yOffset;
							}else{
								finalScale = 1
								charLocation.y = currentY + char.yOffset;
							}
                            charLocation.x = currentX + char.xOffset;
                            currentLine[currentLine.length] = charLocation; // push
                            
                            currentX += char.xAdvance * finalScale;
                            lastCharID = charID;
                            
                            if (charLocation.x + char.width > containerWidth)
                            {
                                if (wordWrap)
                                {
                                    // when autoscaling, we must not split a word in half -> restart
                                    if (autoScale && lastWhiteSpace == -1)
                                        break;

                                    // remove characters and add them again to next line
                                    var numCharsToRemove:int = lastWhiteSpace == -1 ? 1 : i - lastWhiteSpace;

                                    for (j=0; j<numCharsToRemove; ++j) // faster than 'splice'
                                        currentLine.pop();

                                    if (currentLine.length == 0)
                                        break;

                                    i -= numCharsToRemove;
                                }
                                else
                                {
                                    if (autoScale) break;
                                    currentLine.pop();

                                    // continue with next line, if there is one
                                    while (i < numChars - 1 && text.charCodeAt(i) != CHAR_NEWLINE)
                                        ++i;
                                }

                                lineFull = true;
                            }
                        }
                        
                        if (i == numChars - 1)
                        {
                            sLines[sLines.length] = currentLine; // push
                            finished = true;
                        }
                        else if (lineFull)
                        {
                            sLines[sLines.length] = currentLine; // push
                            
                            if (lastWhiteSpace == i)
                                currentLine.pop();
                            
                            if (currentY + leading + 2 * _lineHeight <= containerHeight)
                            {
                                currentLine = CharLocation.vectorFromPool();
                                currentX = 0;
                                currentY += _lineHeight + leading;
                                lastWhiteSpace = -1;
                                lastCharID = -1;
                            }
                            else
                            {
                                break;
                            }
                        }
                    } // for each char
                } // if (_lineHeight <= containerHeight)
                
                if (autoScale && !finished && fontSize > 3)
                    fontSize -= 1;
                else
                    finished = true; 
            } // while (!finished)
            
            var finalLocations:Vector.<CharLocation> = CharLocation.vectorFromPool();
            var numLines:int = sLines.length;
            var bottom:Number = currentY + _lineHeight;
            var yOffset:int = 0;
            
            if (vAlign == Align.BOTTOM)      yOffset =  containerHeight - bottom;
            else if (vAlign == Align.CENTER) yOffset = (containerHeight - bottom) / 2;
            
            for (var lineID:int=0; lineID<numLines; ++lineID)
            {
                var line:Vector.<CharLocation> = sLines[lineID];
                numChars = line.length;
                
                if (numChars == 0) continue;
                
                var xOffset:int = 0;
                var lastLocation:CharLocation = line[line.length-1];
                var right:Number = lastLocation.x - lastLocation.char.xOffset 
                                                  + lastLocation.char.xAdvance;
                
                if (hAlign == Align.RIGHT)       xOffset =  containerWidth - right;
                else if (hAlign == Align.CENTER) xOffset = (containerWidth - right) / 2;
                
                for (var c:int=0; c<numChars; ++c)
                {
                    charLocation = line[c];
					
					//84 is 't'
					if (charLocation.char.isIcon){
						finalScale = getChar(84).height / charLocation.char.height;
						finalScale *= scale;
					}
					else{
						finalScale = scale;
					}
					
                    charLocation.x = scale * (charLocation.x + xOffset + _offsetX) + _padding;
                    charLocation.y = scale * (charLocation.y + yOffset + _offsetY) + _padding;
                    charLocation.scale = finalScale;
					
                    if (charLocation.char.width > 0 && charLocation.char.height > 0)
                        finalLocations[finalLocations.length] = charLocation;
                }
            }
			
            return finalLocations;
        }
        
        /** The name of the font as it was parsed from the font file. */
        public function get name():String { return _name; }
        
        /** The native size of the font. */
        public function get size():Number { return _size; }
        
        /** The height of one line in points. */
        public function get lineHeight():Number { return _lineHeight; }
        public function set lineHeight(value:Number):void { _lineHeight = value; }
        
        /** The smoothing filter that is used for the texture. */ 
        public function get smoothing():String { return _helperImage.textureSmoothing; }
        public function set smoothing(value:String):void { _helperImage.textureSmoothing = value; }
        
        /** The baseline of the font. This property does not affect text rendering;
         *  it's just an information that may be useful for exact text placement. */
        public function get baseline():Number { return _baseline; }
        public function set baseline(value:Number):void { _baseline = value; }
        
        /** An offset that moves any generated text along the x-axis (in points).
         *  Useful to make up for incorrect font data. @default 0. */ 
        public function get offsetX():Number { return _offsetX; }
        public function set offsetX(value:Number):void { _offsetX = value; }
        
        /** An offset that moves any generated text along the y-axis (in points).
         *  Useful to make up for incorrect font data. @default 0. */
        public function get offsetY():Number { return _offsetY; }
        public function set offsetY(value:Number):void { _offsetY = value; }

        /** The width of a "gutter" around the composed text area, in points.
         *  This can be used to bring the output more in line with standard TrueType rendering:
         *  Flash always draws them with 2 pixels of padding. @default 0.0 */
        public function get padding():Number { return _padding; }
        public function set padding(value:Number):void { _padding = value; }

        /** The underlying texture that contains all the chars. */
        public function get texture():Texture { return _texture; }
		
		public function get endIndex():Number {	return _endIndex; }
		public function set endIndex(value:Number):void { _endIndex = value; }
		
		public function get htmlTag():String { return m_htmlTag; }
		public function set htmlTag(value:String):void { m_htmlTag = value;	}
		
		public function get htmlColor():uint {return m_htmlColor; }
		public function set htmlColor(value:uint):void { m_htmlColor = value; }
		
		public function get actualColor():uint { return m_actualColor; }
		public function set actualColor(value:uint):void { m_actualColor = value; }
		
		public function parseIconFontXml(texture:Texture, fontXml:XML, name:String):void
        {
            var scale:Number = texture.scale;
            var frame:Rectangle = texture.frame;
            var frameX:Number = frame ? frame.x : 0;
            var frameY:Number = frame ? frame.y : 0;
            
            _name = StringUtil.clean(fontXml.info.@face);
            _size = parseFloat(fontXml.info.@size) / scale;
            _lineHeight = parseFloat(fontXml.common.@lineHeight) / scale;
            _baseline = parseFloat(fontXml.common.@base) / scale;
            
            if (fontXml.info.@smooth.toString() == "0")
                smoothing = TextureSmoothing.NONE;
            
            if (_size <= 0)
            {
                trace("[Starling] Warning: invalid font size in '" + _name + "' font.");
                _size = (_size == 0.0 ? 16.0 : _size * -1.0);
            }
            
            for each (var charElement:XML in fontXml.chars.char)
            {
                var id:int = parseInt(charElement.@id);
                var xOffset:Number  = parseFloat(charElement.@xoffset)  / scale;
                var yOffset:Number  = parseFloat(charElement.@yoffset)  / scale;
                var xAdvance:Number = parseFloat(charElement.@xadvance) / scale;
                
                var region:Rectangle = new Rectangle();
                region.x = parseFloat(charElement.@x) / scale + frameX;
                region.y = parseFloat(charElement.@y) / scale + frameY;
                region.width  = parseFloat(charElement.@width)  / scale;
                region.height = parseFloat(charElement.@height) / scale;
                
                var tmptexture:Texture = Texture.fromTexture(texture, region);
                var bitmapChar:TextMeshChar = new TextMeshChar(id, tmptexture, xOffset, yOffset, xAdvance, true);
                addIconChar(id, bitmapChar);
            }
            
            for each (var kerningElement:XML in fontXml.kernings.kerning)
            {
                var first:int  = parseInt(kerningElement.@first);
                var second:int = parseInt(kerningElement.@second);
                var amount:Number = parseFloat(kerningElement.@amount) / scale;
                if (second in _chars) getChar(second).addKerning(first, amount);
            }
        }
		
		public function validateHtmlTag(chars:String, startIndex:int):Object{
			var tmpObj:Object = new Object();
			
			m_htmlTag = ""
			
			var tagCharCount:int = 0;
            var attributeFlag:int = 0;
			
			var tagType:int = TagType.None;
			
			endIndex = startIndex;
            var isValidHtmlTag:Boolean = false;
			
			for (var i:int = startIndex ; i < chars.length ; i++){
				
				if (chars.charCodeAt(i) == 62) // ASCII Code of End HTML tag '>'
                {
                    isValidHtmlTag = true;
                    endIndex = i;
                    break;
                }
				
				m_htmlTag += chars.charAt(i);
				
				if (attributeFlag == 1)
                {
                    if (tagType == TagType.None)
                    {
						// Check for attribute type
                        if (chars.charCodeAt(i) == 43 || chars.charCodeAt(i) == 45 || !isNaN(Number(chars.charAt(i))))
                        {
                            tagType = TagType.NumericalValue;
                        }
                        else if (chars.charCodeAt(i) == 35)
                        {
                            tagType = TagType.ColorValue;
                        }
                        else if (chars.charCodeAt(i) == 34)
                        {
                            tagType = TagType.StringValue;
                        }
                        else
                        {
                            tagType = TagType.StringValue;
                        }
					}
				}
				
				if (chars.charCodeAt(i) == 61) // '=' 
                    attributeFlag = 1;
			}
			
			tmpObj["isValidHtmlTag"] = isValidHtmlTag;
			
			if (m_htmlTag.charAt(0) == "#" && m_htmlTag.length == 7) // if Tag begins with # and contains 7 characters.  <#ffffff>
            {
				tmpObj["type"] = TagType.Color;
				m_htmlColor = uint("0x" + m_htmlTag.substr(1));
            }else{
				if (m_htmlTag.indexOf("sprite") > -1){// <sprite=xx>
					tmpObj["type"] = TagType.Sprite;
					tmpObj["value"] = int(m_htmlTag.match(/\d+/g).join(""));
				}else if (m_htmlTag.indexOf("color") > -1){
					tmpObj["type"] = TagType.Color;
					if (m_htmlTag.charAt(6) == "#" && m_htmlTag.length == 13){ // <color=#ffffff>
						m_htmlColor = uint("0x" + m_htmlTag.substr(7));
					}else if (m_htmlTag.length == 6){ // </color>
						m_htmlColor = actualColor;
					}else{
						tmpObj["isValidHtmlTag"] = false;
					}
				}
			}
			
			return tmpObj;
		}
    }
}

import com.michael.textmesh.TextMeshChar;

class CharLocation
{
    public var char:TextMeshChar;
    public var scale:Number;
    public var x:Number;
    public var y:Number;
	public var color:uint;
    
    public function CharLocation(char:TextMeshChar)
    {
        reset(char);
    }

    private function reset(char:TextMeshChar):CharLocation
    {
        this.char = char;
        return this;
    }

    // pooling

    private static var sInstancePool:Vector.<CharLocation> = new <CharLocation>[];
    private static var sVectorPool:Array = [];

    private static var sInstanceLoan:Vector.<CharLocation> = new <CharLocation>[];
    private static var sVectorLoan:Array = [];

    public static function instanceFromPool(char:TextMeshChar):CharLocation
    {
        var instance:CharLocation = sInstancePool.length > 0 ?
            sInstancePool.pop() : new CharLocation(char);

        instance.reset(char);
        sInstanceLoan[sInstanceLoan.length] = instance;

        return instance;
    }

    public static function vectorFromPool():Vector.<CharLocation>
    {
        var vector:Vector.<CharLocation> = sVectorPool.length > 0 ?
            sVectorPool.pop() : new <CharLocation>[];

        vector.length = 0;
        sVectorLoan[sVectorLoan.length] = vector;

        return vector;
    }

    public static function rechargePool():void
    {
        var instance:CharLocation;
        var vector:Vector.<CharLocation>;

        while (sInstanceLoan.length > 0)
        {
            instance = sInstanceLoan.pop();
            instance.char = null;
            sInstancePool[sInstancePool.length] = instance;
        }

        while (sVectorLoan.length > 0)
        {
            vector = sVectorLoan.pop();
            vector.length = 0;
            sVectorPool[sVectorPool.length] = vector;
        }
    }
}
