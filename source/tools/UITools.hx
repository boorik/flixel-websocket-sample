package tools;
import flixel.addons.ui.*;
class UITools
{
    static public function getButton(x:Float, y:Float, width:Float, height:Float, label:Null<String>, onClick:Null<Void->Void>):FlxUIButton
    {
        var b:FlxUIButton = new FlxUIButton(x, y, label, onClick);
		b.loadGraphicSlice9(null, Std.int(width), Std.int(height), null, FlxUI9SliceSprite.TILE_NONE, -1, true);
		b.label.setFormat(20, flixel.util.FlxColor.BLACK);
		b.autoCenterLabel();
        return b;
    }
}