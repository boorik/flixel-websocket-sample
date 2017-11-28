package mp;

import mp.Message;
import mp.Command;
import mp.MasterCommand;
import game.*;
import haxe.*;

import haxe.net.WebSocketServer;
import haxe.net.WebSocket;
import haxe.net.impl.WebSocketGeneric;

using Lambda;

class GameServer {
	static function main() {
		Sys.println("built at " + BuildInfo.getBuildDate());

		// websocket server
		var clients:Array<Client> = [];
		var world = new World();
		var port = 8888;
		var cpt = 0;
		//master server connection
		var msc = WebSocket.create('ws://127.0.0.1:9999');
		var launchTime = Timer.stamp();
		var running = .0;
		// while(msc.readyState != ReadyState.Open && cpt < 200)
		// {
		// 	log(Std.string(msc.readyState));
		// 	Sys.sleep(0.1);
		// 	cpt++;
		// }
		msc.onopen = function(){
			log('registering the game');
			msc.sendString(Serializer.run(Register("test game",0,10)));
		}
		var ws = WebSocketServer.create('0.0.0.0',8888,5000,true);
		msc.onmessageString = function(msg){
			log(msg);
		}
		while (true) {
			try{
				msc.process();
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
							var command:Command = Unserializer.run(msg);
							switch command {
								case Join:
									log('${websocket.host} joined the game');
									if(client.player == null)
										client.player = world.createPlayer();

									var msg = Serializer.run(Joined(client.player.id));
									client.connection.sendString(msg);

								case SetDirection(dir):
									if(client.player != null) client.player.dir = dir;

								case StartMove:
									if(client.player != null) client.player.speed = 3;

								case StopMove:
									if(client.player != null) client.player.speed = 0;
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
					
				Sys.sleep(0.032);

				//game loop
				//if(cpt++ == 32)
				//{
					cpt = 0;
					var state = world.update();

					// clean up the client-player association
					for(object in state.removed) {
						switch clients.find(function(c) return c.player != null && c.player.id == object.id) {
							case null: // hmm....
							case client: client.player = null;
						}
					}

					// boardcast the game state
					var msg = Serializer.run(State(state));
					for(client in clients)
						try {
							client.connection.sendString(msg);
						} catch (e:Dynamic) {}
				//}
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
	public var player:Object;

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