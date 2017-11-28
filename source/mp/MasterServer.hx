package mp;

import mp.Message;
import mp.MasterCommand;
import game.*;
import haxe.*;

import haxe.net.WebSocketServer;
import haxe.net.WebSocket;
import haxe.net.impl.WebSocketGeneric;

using Lambda;

class MasterServer {
	static function main() {
		Sys.println("Master server, built at " + BuildInfo.getBuildDate());

		// websocket server
		var clients:Array<Client> = [];
		var games:Array<Game> = [];
		var world = new World();
		var port = 8888;
		var ws = WebSocketServer.create('0.0.0.0',8585,5000,true);
		var cpt = 0;
		while (true) {
			try{
			
				var websocket = ws.accept();
				if (websocket != null) 
				{
					var client = new Client(websocket);
					//websocket.onopen = onopen;
					websocket.onclose = function() {
						if(client.player != null)
							world.remove(client.player);
						clients.remove(client);
					};
					websocket.onerror = function(msg:String)
					{
						var host = cast(websocket,WebSocketGeneric).host;
						var date = Date.now();
    					var str = DateTools.format(date,"%Y-%m-%d %H:%M:%S");
						log('${host} $msg');
					};

					websocket.onmessageString = function(msg:String)
						{
							var command:MasterCommand = Unserializer.run(msg);
							switch command {
								case Register(name, playerNumber, maxPlayer):
									log('${websocket.host} register a game');
									client.game = {
										name:name,
										host:websocket.host;
										port:8888,
										playerNumber:playerNumber,
										maxPlayer:maxPlayer,
										lastUpdateTime:Timer.stamp()
									};
									games.push(client.game);
									var msg = Serializer.run(GList(games));
									client.connection.sendString(msg);

								case Update(playerNumber, maxPlayer):
									client.game.playerNumber = playerNumber;
									client.game.maxPlayer = maxPlayer;
									client.game.lastUpdateTime = Timer.stamp();
									
								case List:
									var msg = Serializer.run(GList(games));
									client.connection.sendString(msg);
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
					if(t > 20000)
					{
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
		trace('[$dateStr] $str');
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
