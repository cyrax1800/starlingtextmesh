package 
{
	
	import com.michael.textmesh.TextMesh;
	import com.michael.textmesh.TextMeshFont;
	import flash.filesystem.File;
	import flash.geom.Rectangle;
	import starling.display.Sprite;
	import starling.text.TextFormat;
	import starling.textures.TextureAtlas;
	import starling.utils.AssetManager;
	/**
	 * ...
	 * @author Michael
	 */
	public class Game extends Sprite
	{
		
		public static var mInsatance:Game;
		public var assetManager:AssetManager;
		public function Game() 
		{
			mInsatance = this;
			assetManager = new AssetManager();
			assetManager.keepFontXmls = true;
			assetManager.keepAtlasXmls = true;
			assetManager.enqueue(File.applicationDirectory.resolvePath("asset"));
			assetManager.loadQueue(function(ratio:Number):void{
				if (ratio == 1) {
					startGame();
				}
			});
		}
		
		private function startGame():void {
			var fontAtlas:TextureAtlas = assetManager.getTextureAtlas("font");
			var textMeshFont:TextMeshFont = new TextMeshFont(fontAtlas.getTexture("poetsen"), assetManager.getXml("poetsen"));
			textMeshFont.parseIconFontXml(fontAtlas.getTexture("icons"), assetManager.getXml("icons"),"poetsen");
			TextMesh.registerCompositor(textMeshFont, "poetsen");
			
			test1();
		}
		
		public function test1():void{
			var text:String = "This is a banana (" + IconID.getIcons("banana") + ")\n" +
							"Can using hardcode too. eg:<sprite=\"1\">\n" +
							"<color=#80ff0000>This text is red color</color> and " + 
							"<#00ff00>this is green text with different tag</color>\n" +
							"<#0000ff> this text will be blue till end" + IconID.getIcons("soda") + "";
							
			var textField:TextMesh = new TextMesh(425, 150, text , new TextFormat("poetsen", 25, 0xffffff));
			textField.alignPivot();
			textField.x = 512;
			textField.y = 200;
			textField.border = true;
			this.addChild(textField);
		}
		
		public function test2():void{
			var text:String = "Do you want to buy 5 telescope for " + IconID.getIcons("banana") + "1500?";
			
			var textField:TextMesh = new TextMesh(425, 150, text , new TextFormat("poetsen", 25, 0xffffff));
			textField.alignPivot();
			textField.x = 512;
			textField.y = 200;
			textField.border = true;
			this.addChild(textField);
		}
		
		public function test3():void{
			var text:String = 
			IconID.getIcons("banana") + "+25.000, " + 
			IconID.getIcons("banana") + "+250, " + 
			IconID.getIcons("banana") + "+1, " + 
			IconID.getIcons("banana") + "+30";
			
			trace(text);
			
			var textField:TextMesh = new TextMesh(350, 180, text , new TextFormat("poetsen", 26, 0xffffff));
			textField.alignPivot();
			textField.x = 512;
			textField.y = 200;
			textField.border = true;
			this.addChild(textField);
		}
		
		public function test4():void{
			var text:String = "<i>Or<sprite=\"1\">i</i>ginal Text";
			
			var textField:TextMesh = new TextMesh(1024, 200, text , new TextFormat("poetsen", 46, 0xffffff), true);
			textField.alignPivot();
			textField.x = 512;
			textField.y = 400;
			this.addChild(textField);
		}
		
	}

}