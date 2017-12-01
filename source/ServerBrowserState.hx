package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import game.GameDesc;
import haxe.ds.StringMap;
// import flixel.
import haxe.net.WebSocket;
import mp.*;
import haxe.Timer;

class ServerBrowserState extends FlxState
{
    var statusText:FlxText;
    var ws:WebSocket;
    var wsError = false;
    var posY = 300;
	var gameList:Array<GameDesc>;
	override public function create():Void
	{
		super.create();

        FlxG.camera.bgColor = FlxColor.BLACK;

        statusText = new FlxText(0,0,FlxG.width,"Connecting to master server...");
        statusText.setFormat(12,flixel.util.FlxColor.WHITE);
        add(statusText);
        var backButton = tools.UITools.getButton(10, FlxG.height - 50, 200, 40, "Back to title",function(){
            FlxG.switchState(new MenuState());
        });
        add(backButton);
		
		getGameList();
	}
	
	function getGameList()
	{
		        #if localhost
		log('localhost');
        ws = WebSocket.create('ws://localhost:9999',true);
        #else
        ws = WebSocket.create('ws://games.boorik.com:9999',true);
        #end
        ws.onopen = function(){
            log("getting game list...");
            ws.sendString(haxe.Serializer.run(MasterCommand.List));
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
					gameList = list;
					ws.close();
					
                    for(g in list)
                    {
						
						
                        log(Std.string(g));
                        var gameButton = tools.UITools.getButton(0,posY,500,50,'${g.name} ${g.playerNumber}/${g.maxPlayer} , latency :', function(){
                            Globals.online = true;
                            Globals.game = g;
                            FlxG.switchState(new PlayState());
                        });
                        gameButton.screenCenter(flixel.util.FlxAxes.X);
                        add(gameButton);
                        posY += 60;

                        //ping request
                        var ping:Float;
                        var pingws = WebSocket.create('ws://${g.host}:${g.port}',true);
                        pingws.onopen = function(){
                            ping = Timer.stamp();
                            pingws.sendString(haxe.Serializer.run(Command.Ping));
                        }
                        pingws.onerror = function (msg:String){
                            log('ERROR : Unable to communicate with ${g.host}');
                        };
                        pingws.onmessageString = function(gamemsg:String){
                            var message:Message;
                            try{
                                message = haxe.Unserializer.run(gamemsg);
                            }
                            catch(e:Dynamic)
                            {
                                log('ERROR : malformed message : $msg');
                                return;
                            }
                            switch(message)
                            {
                                case Pong :
                                    var pong = Std.int((Timer.stamp() - ping)*1000);
                                    gameButton.label.text += Std.string(pong);
                                    pingws.close();
                                default :
                                    log('not supposed to receive this message type : $message');
                            }
                        }
                        
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