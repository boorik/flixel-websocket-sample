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
    var wsError = false;
    var posY = 300;
	override public function create():Void
	{
		super.create();

        statusText = new FlxText(0,0,FlxG.width,"Connecting to master server...");
        statusText.setFormat(20,flixel.util.FlxColor.WHITE);
        add(statusText);
        ws = WebSocket.create('ws://pony.boorik.com:9999');
        ws.onopen = function(){
            log("getting game list...");
            ws.sendString(haxe.Serializer.run(List));
        }
        ws.onerror = function (msg:String){
            log("ERRROR : Unable to communicate with master server\nType ESC key to go back.");
        };
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
                        var gameButton = tools.UITools.getButton(0,posY,300,50,'${g.name} ${g.playerNumber}/${g.maxPlayer}', function(){
                            Globals.online = true;
                            Globals.game = g;
                            FlxG.switchState(new PlayState());
                        });
                        gameButton.screenCenter(flixel.util.FlxAxes.X);
                        add(gameButton);
                        posY += 60;

                    }
                default :
                    log('not supposed to receive this message type : $masterMessage');
            }
        };
	}
    
    override public function destroy()
    {
        if(ws != null)
        {
            ws.close();
            ws = null;
        }
        super.destroy();
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
        if(!wsError)
        {
            try{
            ws.process();
            }
            catch(e:Dynamic)
            {
            wsError = true; 
            }
        }
		if(FlxG.keys.justPressed.ESCAPE)
		{
            FlxG.switchState(new MenuState());
		}
		super.update(elapsed);
	}
}