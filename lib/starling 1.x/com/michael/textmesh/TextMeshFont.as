// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2014 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package com.michael.textmesh
{
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;
	import mx.utils.StringUtil;
    
    import starling.display.Image;
    import starling.display.QuadBatch;
    import starling.display.Sprite;
    import starling.textures.Texture;
    import starling.textures.TextureSmoothing;
    import starling.utils.HAlign;
    import starling.utils.VAlign;
    import starling.utils.cleanMasterString;

    /** The BitmapFont class parses bitmap font files and arranges the glyphs 
     *  in the form of a text.
     *
     *  The class parses the XML format as it is used in the 
     *  <a href="http://www.angelcode.com/products/bmfont/">AngelCode Bitmap Font Generator</a> or
     *  the <a href="http://glyphdesigner.71squared.com/">Glyph Designer</a>. 
     *  This is what the file format looks like:
     *
     *  <pre> 
     *  &lt;font&gt;
     *    &lt;info face="BranchingMouse" size="40" /&gt;
     *    &lt;common lineHeight="40" /&gt;
     *    &lt;pages&gt;  &lt;!-- currently, only one page is supported --&gt;
     *      &lt;page id="0" file="texture.png" /&gt;
     *    &lt;/pages&gt;
     *    &lt;chars&gt;
     *      &lt;char id="32" x="60" y="29" width="1" height="1" xoffset="0" yoffset="27" xadvance="8" /&gt;
     *      &lt;char id="33" x="155" y="144" width="9" height="21" xoffset="0" yoffset="6" xadvance="9" /&gt;
     *    &lt;/chars&gt;
     *    &lt;kernings&gt; &lt;!-- Kerning is optional --&gt;
     *      &lt;kerning first="83" second="83" amount="-4"/&gt;
     *    &lt;/kernings&gt;
     *  &lt;/font&gt;
     *  </pre>
     *  
     *  Pass an instance of this class to the method <code>registerBitmapFont</code> of the
     *  TextField class. Then, set the <code>fontName</code> property of the text field to the 
     *  <code>name</code> value of the bitmap font. This will make the text field use the bitmap
     *  font.  
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
        
        private var mTexture:Texture;
        private var mChars:Dictionary;
        private var mCharsImage:Dictionary;
        private var mName:String;
        private var mSize:Number;
        private var mLineHeight:Number;
        private var mBaseline:Number;
        private var mOffsetX:Number;
        private var mOffsetY:Number;
        private var mHelperImage:Image;

        /** Helper objects. */
        private static var sLines:Array = [];
		
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
            else if (texture != null && fontXml == null)
            {
                throw new ArgumentError("fontXml cannot be null!");
            }
            
            mName = "unknown";
            mLineHeight = mSize = mBaseline = 14;
            mOffsetX = mOffsetY = 0.0;
            mTexture = texture;
            mChars = new Dictionary();
            mCharsImage = new Dictionary();
            mHelperImage = new Image(texture);
            
            parseFontXml(fontXml);
        }
        
        /** Disposes the texture of the bitmap font! */
        public function dispose():void
        {
            if (mTexture)
                mTexture.dispose();
        }
        
        private function parseFontXml(fontXml:XML):void
        {
            var scale:Number = mTexture.scale;
            var frame:Rectangle = mTexture.frame;
            var frameX:Number = frame ? frame.x : 0;
            var frameY:Number = frame ? frame.y : 0;
            
            mName = cleanMasterString(fontXml.info.@face);
            mSize = parseFloat(fontXml.info.@size) / scale;
            mLineHeight = parseFloat(fontXml.common.@lineHeight) / scale;
            mBaseline = parseFloat(fontXml.common.@base) / scale;
            
            if (fontXml.info.@smooth.toString() == "0")
                smoothing = TextureSmoothing.NONE;
            
            if (mSize <= 0)
            {
                trace("[Starling] Warning: invalid font size in '" + mName + "' font.");
                mSize = (mSize == 0.0 ? 16.0 : mSize * -1.0);
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
                
                var texture:Texture = Texture.fromTexture(mTexture, region);
                var bitmapChar:TextMeshChar = new TextMeshChar(id, texture, xOffset, yOffset, xAdvance); 
                addChar(id, bitmapChar);
            }
            
            for each (var kerningElement:XML in fontXml.kernings.kerning)
            {
                var first:int  = parseInt(kerningElement.@first);
                var second:int = parseInt(kerningElement.@second);
                var amount:Number = parseFloat(kerningElement.@amount) / scale;
                if (second in mChars) getChar(second).addKerning(first, amount);
            }
        }
        
        /** Returns a single bitmap char with a certain character ID. */
        public function getChar(charID:int):TextMeshChar
        {
            return mChars[charID];   
        }
		
		/** Returns a single iamge bitmap char with a certain character ID. */
        public function getImageChar(charID:int):TextMeshChar
        {
            return mCharsImage[charID];
        }
        
        /** Adds a bitmap char with a certain character ID. */
        public function addChar(charID:int, bitmapChar:TextMeshChar):void
        {
            mChars[charID] = bitmapChar;
        }
		
		/** Adds a icon bitmap char with a certain character ID. */
        public function addIconChar(charID:int, bitmapChar:TextMeshChar):void
        {
            mCharsImage[charID] = bitmapChar;
        }
        
        /** Returns a vector containing all the character IDs that are contained in this font. */
        public function getCharIDs(result:Vector.<int>=null):Vector.<int>
        {
            if (result == null) result = new <int>[];

            for(var key:* in mChars)
                result[result.length] = int(key);

            return result;
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
                                     fontSize:Number=-1, color:uint=0xffffff, 
                                     hAlign:String="center", vAlign:String="center",      
                                     autoScale:Boolean=true, 
                                     kerning:Boolean=true):Sprite
        {
            var charLocations:Vector.<CharLocation> = arrangeChars(width, height, text, fontSize, 
                                                                   hAlign, vAlign, autoScale, kerning);
            var numChars:int = charLocations.length;
            var sprite:Sprite = new Sprite();
            
            for (var i:int=0; i<numChars; ++i)
            {
                var charLocation:CharLocation = charLocations[i];
                var char:Image = charLocation.char.createImage();
                char.x = charLocation.x;
                char.y = charLocation.y;
                char.scaleX = char.scaleY = charLocation.scale;
                char.color = color;
                sprite.addChild(char);
            }
            
            CharLocation.rechargePool();
            return sprite;
        }
        
        /** Draws text into a QuadBatch. */
        public function fillQuadBatch(quadBatch:QuadBatch, width:Number, height:Number, text:String,
                                      fontSize:Number=-1, color:uint=0xffffff, 
                                      hAlign:String="center", vAlign:String="center",      
                                      autoScale:Boolean=true, 
                                      kerning:Boolean=true, leading:Number=0):void
        {
			if (color == 0xffffff) color = color - 1;
			actualColor = color;
            var charLocations:Vector.<CharLocation> = arrangeChars(
                    width, height, text, fontSize, hAlign, vAlign, autoScale, kerning, leading);
            var numChars:int = charLocations.length;
            mHelperImage.color = color;
            
            for (var i:int=0; i<numChars; ++i)
            {
                var charLocation:CharLocation = charLocations[i];
                mHelperImage.texture = charLocation.char.texture;
                mHelperImage.readjustSize();
                mHelperImage.x = charLocation.x;
                mHelperImage.y = charLocation.y;
                mHelperImage.scaleX = mHelperImage.scaleY = charLocation.scale;
                mHelperImage.color = charLocation.color;
				trace("[TextMesh] " + mHelperImage.color);
                quadBatch.addImage(mHelperImage);
            }

            CharLocation.rechargePool();
        }
        
        /** Arranges the characters of a text inside a rectangle, adhering to the given settings. 
         *  Returns a Vector of CharLocations. */
        private function arrangeChars(width:Number, height:Number, text:String, fontSize:Number=-1,
                                      hAlign:String="center", vAlign:String="center",
                                      autoScale:Boolean=true, kerning:Boolean=true,
                                      leading:Number=0):Vector.<CharLocation>
        {
            if (text == null || text.length == 0) return CharLocation.vectorFromPool();
            if (fontSize < 0) fontSize *= -mSize;
            
            var finished:Boolean = false;
            var charLocation:CharLocation;
            var numChars:int;
            var containerWidth:Number;
            var containerHeight:Number;
            var scale:Number;
			var finalScale:Number;
			
			m_htmlColor = actualColor;
            
            while (!finished)
            {
                sLines.length = 0;
                scale = fontSize / mSize;
                containerWidth  = width / scale;
                containerHeight = height / scale;
                
                if (mLineHeight <= containerHeight)
                {
                    var lastWhiteSpace:int = -1;
                    var lastCharID:int = -1;
                    var currentX:Number = 0;
                    var currentY:Number = 0;
                    var currentLine:Vector.<CharLocation> = CharLocation.vectorFromPool();
                    
                    numChars = text.length;
                    for (var i:int=0; i<numChars; ++i)
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
									//continue;
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
                            trace("[Starling] Missing character: " + charID);
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
								finalScale = getChar(84).height / char.height; // 84 = charcter "t"
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
                                // when autoscaling, we must not split a word in half -> restart
                                if (autoScale && lastWhiteSpace == -1)
                                    break;

                                // remove characters and add them again to next line
                                var numCharsToRemove:int = lastWhiteSpace == -1 ? 1 : i - lastWhiteSpace;

                                for (var j:int=0; j<numCharsToRemove; ++j) // faster than 'splice'
                                    currentLine.pop();
                                
                                if (currentLine.length == 0)
                                    break;
                                
                                i -= numCharsToRemove;
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
                            
                            if (currentY + leading + 2 * mLineHeight <= containerHeight)
                            {
                                currentLine = CharLocation.vectorFromPool();
                                currentX = 0;
                                currentY += mLineHeight + leading;
                                lastWhiteSpace = -1;
                                lastCharID = -1;
                            }
                            else
                            {
                                break;
                            }
                        }
                    } // for each char
                } // if (mLineHeight <= containerHeight)
                
                if (autoScale && !finished && fontSize > 3)
                    fontSize -= 1;
                else
                    finished = true; 
            } // while (!finished)
            
            var finalLocations:Vector.<CharLocation> = CharLocation.vectorFromPool();
            var numLines:int = sLines.length;
            var bottom:Number = currentY + mLineHeight;
            var yOffset:int = 0;
            
            if (vAlign == VAlign.BOTTOM)      yOffset =  containerHeight - bottom;
            else if (vAlign == VAlign.CENTER) yOffset = (containerHeight - bottom) / 2;
            
            for (var lineID:int=0; lineID<numLines; ++lineID)
            {
                var line:Vector.<CharLocation> = sLines[lineID];
                numChars = line.length;
                
                if (numChars == 0) continue;
                
                var xOffset:int = 0;
                var lastLocation:CharLocation = line[line.length-1];
                var right:Number = lastLocation.x - lastLocation.char.xOffset 
                                                  + lastLocation.char.xAdvance;
                
                if (hAlign == HAlign.RIGHT)       xOffset =  containerWidth - right;
                else if (hAlign == HAlign.CENTER) xOffset = (containerWidth - right) / 2;
                
                for (var c:int=0; c<numChars; ++c)
                {
                    charLocation = line[c];
					
					if (charLocation.char.isIcon){
						finalScale = getChar(84).height / charLocation.char.height;
						finalScale *= scale;
					}
					else{
						finalScale = scale;
					}
					
                    charLocation.x = scale * (charLocation.x + xOffset + mOffsetX);
                    charLocation.y = scale * (charLocation.y + yOffset + mOffsetY);
                    charLocation.scale = finalScale;
					
                    if (charLocation.char.width > 0 && charLocation.char.height > 0)
                        finalLocations[finalLocations.length] = charLocation;
                }
            }
            
            return finalLocations;
        }
        
        /** The name of the font as it was parsed from the font file. */
        public function get name():String { return mName; }
        
        /** The native size of the font. */
        public function get size():Number { return mSize; }
        
        /** The height of one line in points. */
        public function get lineHeight():Number { return mLineHeight; }
        public function set lineHeight(value:Number):void { mLineHeight = value; }
        
        /** The smoothing filter that is used for the texture. */ 
        public function get smoothing():String { return mHelperImage.smoothing; }
        public function set smoothing(value:String):void { mHelperImage.smoothing = value; } 
        
        /** The baseline of the font. This property does not affect text rendering;
         *  it's just an information that may be useful for exact text placement. */
        public function get baseline():Number { return mBaseline; }
        public function set baseline(value:Number):void { mBaseline = value; }
        
        /** An offset that moves any generated text along the x-axis (in points).
         *  Useful to make up for incorrect font data. @default 0. */ 
        public function get offsetX():Number { return mOffsetX; }
        public function set offsetX(value:Number):void { mOffsetX = value; }
        
        /** An offset that moves any generated text along the y-axis (in points).
         *  Useful to make up for incorrect font data. @default 0. */
        public function get offsetY():Number { return mOffsetY; }
        public function set offsetY(value:Number):void { mOffsetY = value; }

        /** The underlying texture that contains all the chars. */
        public function get texture():Texture { return mTexture; }
		
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
            
            mName = StringUtil.trim(fontXml.info.@face);
            mSize = parseFloat(fontXml.info.@size) / scale;
            mLineHeight = parseFloat(fontXml.common.@lineHeight) / scale;
            mBaseline = parseFloat(fontXml.common.@base) / scale;
            
            if (fontXml.info.@smooth.toString() == "0")
                smoothing = TextureSmoothing.NONE;
            
            if (mSize <= 0)
            {
                trace("[Starling] Warning: invalid font size in '" + mName + "' font.");
                mSize = (mSize == 0.0 ? 16.0 : mSize * -1.0);
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
                if (second in mCharsImage) getImageChar(second).addKerning(first, amount);
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
				if (m_htmlTag.indexOf("sprite") > -1){// <sprite=2>
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