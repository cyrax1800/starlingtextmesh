package
{
	import flash.utils.Dictionary;

	public class IconID 
	{

		private static var iconDictionary:Dictionary = new Dictionary();
		{
			iconDictionary["apple"] = 1
			iconDictionary["banana"] = 2
			iconDictionary["coffee"] = 3
			iconDictionary["fried_fries"] = 4
			iconDictionary["hamburger"] = 5
			iconDictionary["mushroom"] = 6
			iconDictionary["soda"] = 7
		}

		public static function getIcons(name:String):String{
			name = name.toLowerCase().replace(/ /g, "_");
			if (iconDictionary[name] == undefined) throw new ArgumentError(name + " not in dictionary");
			return "<sprite=\"" + iconDictionary[name] + "\">";
		}

	}

}

