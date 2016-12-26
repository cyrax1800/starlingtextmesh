from xml.dom import minidom

def createCharTag(id,x,y,width,height):
    yOffset = int(height);
    return "\t\t<char id=\"" + str(id) + "\" x=\"" + str(x) + "\" y=\"" + str(y) + "\" width=\"" + str(width) + "\" height=\"" + str(height) +  "\" xoffset=\"0\" yoffset=\"" + str(yOffset) + "\" xadvance=\"" + str(width) + "\" page=\"0\" chnl=\"15\"/>";

name = [];
lines = [];
lines.append("<font keepTexture=\"true\" keepXml=\"true\">")
lines.append("\t<info face=\"test\" size=\"48\" bold=\"0\" italic=\"0\" charset=\"\" unicode=\"1\" stretchH=\"100\" smooth=\"1\" aa=\"1\" padding=\"2,2,2,2\" spacing=\"0,0\" outline=\"0\"/>")
lines.append("\t<common lineHeight=\"58\" base=\"48\" scaleW=\"512\" scaleH=\"256\" pages=\"1\" packed=\"0\"/>")
lines.append("\t<pages>")
lines.append("\t\t<page id=\"0\" keepTexture=\"true\" file=\"icons.png\"/>")
lines.append("\t</pages>")

##get file name
doc = minidom.parse("icons.xml")

subTextures = doc.getElementsByTagName("SubTexture")
lines.append("\t<chars count=\"" + str(len(subTextures)) + "\">")

i = 1;
for subTexture in subTextures:
    id = i;
    name.append(subTexture.getAttribute("name"))
    x = subTexture.getAttribute("x")
    y = subTexture.getAttribute("y")
    width = subTexture.getAttribute("width")
    height = subTexture.getAttribute("height")
    lines.append(createCharTag(id,x,y,width,height));
    i += 1;
    
lines.append("\t</chars>")
lines.append("</font>")

file = open("icons.fnt", "w")
for i in range (len(lines)):
    file.write(lines[i])
    file.write("\n");
file.close()

file = open("IconId.as", "w")
file.write("package\n")
file.write("{\n")
file.write("\timport flash.utils.Dictionary;\n")
file.write("\n");
file.write("\tpublic class IconID \n")
file.write("\t{\n")
file.write("\n");
file.write("\t\tprivate static var iconDictionary:Dictionary = new Dictionary();\n")
file.write("\t\t{\n")
for i in range (len(name)):
    file.write("\t\t\ticonDictionary[\"" + name[i] + "\"] = " + str(i + 1));
    file.write("\n");
file.write("\t\t}\n")
file.write("\n");
file.write("\t\tpublic static function getIcons(name:String):String{\n")
file.write("\t\t\tname = name.toLowerCase().replace(/ /g, \"_\");\n")
file.write("\t\t\tif (iconDictionary[name] == undefined) throw new ArgumentError(name + \" not in dictionary\");\n")
file.write("\t\t\treturn \"<sprite=\\\"\" + iconDictionary[name] + \"\\\">\";\n")
file.write("\t\t}\n\n")
file.write("\t}\n\n")
file.write("}\n\n")
file.close()
