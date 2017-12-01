package mp;

import mp.Message;
import mp.MasterCommand;
import mp.MasterMessage;

import game.*;
import haxe.*;

import haxe.net.WebSocketServer;
import haxe.net.WebSocket;
import haxe.net.impl.WebSocketGeneric;

using Lambda;

class MasterServer {
	static function main() {
		log("MASTER SERVER STARTED\nbuilt at " + BuildInfo.getBuildDate());

		// websocket server
		var clients:Array<Client> = [];
		var games:Array<GameDesc> = [];
		var world = new World();
		var port = 8888;
		var ws = WebSocketServer.create('0.0.0.0',9999,500, false);
		var cpt = 0;
		while (true) {
			try{
			
				var websocket = ws.accept();
				if (websocket != null) 
				{
					var client = new Client(websocket);
					websocket.onopen = function(){log('hello client');};
					websocket.onclose = function() {
						log('client disconnected');
						if(client.game != null)
							games.remove(client.game);
						client.game = null;
						clients.remove(client);
					};
					websocket.onerror = function(msg:String)
					{
						var host = cast(websocket,WebSocketGeneric).socket.peer().host;
						var date = Date.now();
    					var str = DateTools.format(date,"%Y-%m-%d %H:%M:%S");
						log('${host} $msg');
					};

					websocket.onmessageString = function(msg:String)
						{
							var command:MasterCommand;
							try{
							command = cast(Unserializer.run(msg),MasterCommand);
							}catch(e:Dynamic){
								log('malformed message : $msg');
								log(Std.string(e));
								return;
							}
							switch command {
								case Register(name, port, playerNumber, maxPlayer):
									var peer = cast(websocket,WebSocketGeneric).socket.peer().host.toString();
									log('$peer register a game');
									client.game = {
										name:name,
										host:peer,
										port:port,
										playerNumber:playerNumber,
										maxPlayer:maxPlayer,
										lastUpdateTime:Timer.stamp()
									};
									games.push(client.game);
									var msg = Serializer.run(Registered);
									client.connection.sendString(msg);

								case Update(playerNumber, maxPlayer):
									client.game.playerNumber = playerNumber;
									client.game.maxPlayer = maxPlayer;
									client.game.lastUpdateTime = Timer.stamp();
									var msg = Serializer.run(Updated);
									client.connection.sendString(msg);

								case List:
									var msg = Serializer.run(GList(games));
									client.connection.sendString(msg);

								default :
									log('ERROR : unexpected command : $command');
							}
						};
					clients.push(client);
				}
				
				var toRemove = [];
				for (handler in clients) {
					if (!handler.update()) {
						toRemove.push(handler);
					}
				}
				
				while (toRemove.length > 0)
					clients.remove(toRemove.pop());

				//removed not updated games
				var unavailables = [];
				var current = Timer.stamp();
				for(g in games)
				{
					var t = current - g.lastUpdateTime;
					if(t > 30)
					{
						log("game too old removing");
						unavailables.push(g);
					}
				}
				while(unavailables.length > 0)
					games.remove(unavailables.pop());
					
				Sys.sleep(0.032);
			}
			catch (e:Dynamic) {
				trace('Error', e);
				trace(CallStack.exceptionStack());
			}
		}
	}
	static function log(str:String)
	{
		var date = Date.now();
		var dateStr = DateTools.format(date,"%Y-%m-%d %H:%M:%S");
		Sys.println('[$dateStr] $str');
	}
}

class Client {
	public var connection(default, null):WebSocket;
	public var game:GameDesc;

	public function new(connection)
		this.connection = connection;

	public function update()
	{
		connection.process();
		return connection.readyState != Closed;
	}
}

/*
class Connection extends haxe.net.WebSocket
{
	public function send(m:String)
	{
		this.sendString(m);
	}
}
*/
