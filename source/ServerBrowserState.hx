package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.addons.ui.FlxButtonPlus;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
// import flixel.
import haxe.net.WebSocket;
import mp.MasterCommand;
import mp.MasterMessage;

class ServerBrowserState extends FlxState
{
    var statusText:FlxText;
    var ws:WebSocket;
    var posY = 300;
	override public function create():Void
	{
		super.create();

        statusText = new FlxText(0,0,FlxG.width,"Connecting to master server...");
        statusText.setFormat(20,flixel.util.FlxColor.WHITE);
        add(statusText);
        ws = WebSocket.create('ws://localhost:9999');
        ws.onopen = function(){
            log("getting game list...");
            ws.sendString(haxe.Serializer.run(List));
        }
        ws.onmessageString = function(msg:String){
            var masterMessage:MasterMessage;
            try{
                masterMessage = haxe.Unserializer.run(msg);
            }
            catch(e:Dynamic)
            {
                log('ERROR : malformed message : $msg');
                return;
            }
            switch(masterMessage)
            {
                case GList(list):
                    log('done.');
                    for(g in list)
                    {
                        log(Std.string(g));
                        var gameButton = new FlxButton(0,posY,'${g.name} ${g.playerNumber}/${g.maxPlayer}', function(){
                            Globals.online = true;
                            Globals.game = g;
                            FlxG.switchState(new PlayState());
                        });
                        gameButton.setGraphicSize(300,100);
                        gameButton.label.setFormat(20);
                        gameButton.label.fieldWidth = 300;
                        gameButton.label.autoSize = true;
                        gameButton.label.borderColor = FlxColor.RED;
                        gameButton.label.borderStyle = flixel.text.FlxTextBorderStyle.OUTLINE_FAST;
                        gameButton.label.borderSize = 2;
                        gameButton.screenCenter(flixel.util.FlxAxes.X);
                        gameButton.updateHitbox();
                        add(gameButton);
                        posY += 40;

                    }
                default :
                    log('not supposed to receive this message type : $masterMessage');
            }
        };
	}

    function log(msg:String)
    {
        statusText.text+='\n$msg';
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
        ws.process();
		if(FlxG.keys.justPressed.ESCAPE)
		{
            Sys.exit(0);
		}
		super.update(elapsed);
	}
}