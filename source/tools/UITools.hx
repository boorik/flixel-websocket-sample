package tools;
import flixel.addons.ui.*;
class UITools
{
    static public function getButton(x:Int, y:Int, width:Int, height:Int, label:Null<String>, onClick:Null<Void->Void>):FlxUIButton
    {
        var b:FlxUIButton = new FlxUIButton(0, 0, label, onClick);
		b.loadGraphicSlice9(null, width, height, null, FlxUI9SliceSprite.TILE_NONE, -1, true);
		b.label.setFormat(20, flixel.util.FlxColor.BLACK);
		b.autoCenterLabel();
        return b;
    }
}