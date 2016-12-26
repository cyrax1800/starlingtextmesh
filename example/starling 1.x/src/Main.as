package
{
	import flash.desktop.NativeApplication;
	import flash.events.Event;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	import starling.core.Starling;
	
	/**
	 * ...
	 * @author Michael
	 */
	[SWF(width="1024", height="600", frameRate="60", backgroundColor="#CECECE")]
	public class Main extends Sprite 
	{
		private var mStarling:Starling;
		public function Main() 
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.DEACTIVATE, deactivate);
			
			// touch or gesture?
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
			
			//Mesh.defaultStyle = MultiTextureStyle;
			
			mStarling = new Starling(Game, stage, null, null, "auto", "auto");
			mStarling.start();
			
			mStarling.showStats = true;
			// Entry point
			// New to AIR? Please read *carefully* the readme.txt files!
		}
		
		private function deactivate(e:Event):void 
		{
			// make sure the app behaves well (or exits) when in background
			//NativeApplication.nativeApplication.exit();
		}
		
	}
	
}