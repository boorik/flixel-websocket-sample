package mp;

import mp.Message;
import mp.Command;
import mp.MasterCommand;
import mp.MasterMessage;
import game.*;
import haxe.*;

import haxe.net.WebSocketServer;
import haxe.net.WebSocket;
import haxe.net.impl.WebSocketGeneric;

using Lambda;

class GameServer {
	static function main() {
		Sys.println("built at " + BuildInfo.getBuildDate());

		var masterRefreshRate = 5.0; //refresh master server every 5 sec

		// websocket server
		var clients:Array<Client> = [];
		var world = new World();
		var port = 8888;
		var cpt = 0;
		//game server sockets
		var ws = WebSocketServer.create('0.0.0.0',8888,5000,true);

		//master server connection
		var msc = WebSocket.create('ws://pony.boorik.com:9999');
		var masterUpdateTime = .0;
		var running = .0;
		var mscError = false;

		msc.onopen = function(){
			log('registering the game');
			msc.sendString(Serializer.run(Register("test game", 0, world.maxPlayer)));
		}

		msc.onerror = function(msg:String){
			log('ERROR : issue with master server \n$msg');
			mscError = true;
		}

		msc.onclose = function(){
			log("ERROR : connection to master server lost");
		}
		
		msc.onmessageString = function(msg){
			var command:MasterMessage;
			try{
				command = Unserializer.run(msg);
			}
			catch(e:Dynamic)
			{
				log('ERROR : unexpected message: $msg');
				return;
			}
			switch(command)
			{
				case Registered :
					log("registered to master server");
					masterUpdateTime = Timer.stamp();

				case Updated :
					//log("master server updated");
					masterUpdateTime = Timer.stamp();
				
				default:
					log('ERROR : not supposed to recieve $command message');
			}
		}
		while (true) {
			try{
				if(!mscError)
				{
					try{
						msc.process();
					}
					catch(e:Dynamic)
					{
						log('ERROR : Unable to communicate with master server,\n$e');
						mscError = true;
					}
				}

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
						log('${host} $msg');
					};

					websocket.onmessageString = function(msg:String)
						{
							var command:Command;
							try{
								command = Unserializer.run(msg);
							}
							catch(e:Dynamic)
							{
								log('ERROR : unexpected message: $msg');
								return;
							}
							switch command {
								case Join:
									if(world.playerNumber < world.maxPlayer)
									{
										var peer = cast(websocket,WebSocketGeneric).socket.peer().host.toString();
										log('$peer joined the game');
										if(client.player == null)
											client.player = world.createPlayer();

										var msg = Serializer.run(Joined(client.player.id));
										client.connection.sendString(msg);
									}
									else
									{
										var msg = Serializer.run(Full);
										client.connection.sendString(msg);
									}

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

				//keep master server in touch
				if(masterUpdateTime != .0 && (Timer.stamp() - masterUpdateTime > masterRefreshRate))
				{
					masterUpdateTime = .0;
					msc.sendString(Serializer.run(Update(world.playerNumber, world.maxPlayer)));
				}


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

					// broadcast the game state
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
		Sys.println('[$dateStr] $str');
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
