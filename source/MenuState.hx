package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.addons.ui.FlxButtonPlus;
import flixel.math.FlxMath;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUI9SliceSprite;


class MenuState extends FlxState
{
	override public function create():Void
	{
		super.create();

		var soloButton = tools.UITools.getButton(0, FlxG.height - 110, 300, 50, "Play solo", playSolo);
		soloButton.screenCenter(flixel.util.FlxAxes.X);
		add(soloButton);

		var multiButton = tools.UITools.getButton(0,FlxG.height - 55, 300, 50, "Play online", playMulti);
		multiButton.screenCenter(flixel.util.FlxAxes.X);
		add(multiButton);
	}

	function playSolo()
	{
		Globals.online = false;
		FlxG.switchState(new PlayState());
	}

	function playMulti()
	{
		Globals.online = true;
		FlxG.switchState(new ServerBrowserState());
	}

	override public function update(elapsed:Float):Void
	{
		#if !web
		if(FlxG.keys.justPressed.ESCAPE)
		{
			Sys.exit(0);
		}
		#end
		super.update(elapsed);
	}
}
