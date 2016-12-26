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
	import starling.display.QuadBatch;

    /** A text compositor arranges letters for Starling's TextField. */
    public interface ITextCompositor
    {
        /** Draws the given text into a MeshBatch, using the supplied format and options. */
        function fillQuadBatch(quadBatch:QuadBatch, width:Number, height:Number, text:String,
                                      fontSize:Number=-1, color:uint=0xffffff, 
                                      hAlign:String="center", vAlign:String="center",      
                                      autoScale:Boolean=true, 
                                      kerning:Boolean=true, leading:Number=0):void;

        /** Clears the MeshBatch (filled by the same class) and disposes any resources that
         *  are no longer needed. */
        //function clearQuadBatch(quadBatch:QuadBatch):void;

        /** Frees all resources allocated by the compositor. */
        function dispose():void;
    }
}
