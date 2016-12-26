package com.michael.textmesh
{
	import flash.utils.Dictionary;
	import starling.text.BitmapChar;

    import starling.display.Image;
    import starling.textures.Texture;

    /** A BitmapChar contains the information about one char of a bitmap font.
     *  <em>You don't have to use this class directly in most cases. 
     *  The TextField class contains methods that handle bitmap fonts for you.</em>    
     */ 
    public class TextMeshChar extends BitmapChar
    {
		private var _isIcon:Boolean;
        
        /** Creates a char with a texture and its properties. */
        public function TextMeshChar(id:int, texture:Texture, 
                                   xOffset:Number, yOffset:Number, xAdvance:Number,isIcon:Boolean = false)
        {
            super(id, texture, xOffset, yOffset, xAdvance)
			_isIcon = isIcon;
        }
		
		public function get isIcon():Boolean { return _isIcon; }
		
		public function set isIcon(value:Boolean):void { _isIcon = value; }
    }

}