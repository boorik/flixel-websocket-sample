package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.addons.ui.FlxButtonPlus;
import flixel.math.FlxMath;

class MenuState extends FlxState
{
	override public function create():Void
	{
		super.create();

		var soloButton:FlxButtonPlus = new FlxButtonPlus(0, 0, playSolo, "Solo game", 300, 30);
		soloButton.screenCenter(flixel.util.FlxAxes.X);
		soloButton.y = 500;
		add(soloButton);

		var multiButton:FlxButton = new FlxButton(0, 0, "Online game", playMulti);
		multiButton.screenCenter(flixel.util.FlxAxes.X);
		multiButton.y = 600;
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
		FlxG.switchState(new PlayState());
	}

	override public function update(elapsed:Float):Void
	{

		if(FlxG.keys.justPressed.ESCAPE)
		{
			openfl.Lib.close();
		}
		super.update(elapsed);
	}
}
