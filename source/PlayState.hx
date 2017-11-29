package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

using flixel.util.FlxSpriteUtil;

import game.*;
import game.Object;
using Lambda;

import haxe.*;
import haxe.ds.IntMap;
// import haxe.Serializer;
// import haxe.Unserializer;
import mp.Command;
import mp.Message;

class PlayState extends FlxState
{
	var world:World;
	var state:GameState;
	var connected = false;
	var id:Null<Int> = null;
	var touched:Bool;
	var ws:haxe.net.WebSocket;
	var sprites:IntMap<FlxSprite>;

	//debug var
	var worldUpdateTime:Float;
	var worldTreat:Float;
	var stateUpdate:Float;

	override public function create():Void
	{
		//debug
		FlxG.watch.add(this,'worldUpdateTime');
		FlxG.watch.add(this,'worldTreat');
		FlxG.watch.add(this,'stateUpdate');

		trace("built at " + BuildInfo.getBuildDate());

		sprites = new IntMap<FlxSprite>();
		if(Globals.online)
		{
			ws = haxe.net.WebSocket.create("ws://127.0.0.1:8888");
			ws.onopen = function() ws.sendString(Serializer.run(Join));
			ws.onmessageString = function(msg) {
				var msg:Message = Unserializer.run(msg);
				switch msg {
					case Joined(id): 
						trace('Game joined, player id: $id');
						this.id = id;
					case Full:
						trace('Unable to join, the game is full');
					case State(state): 
						this.state = state;
				}
			}
			ws.onerror = function(msg:String){
				trace('Network error : $msg');
			}
		}
		else
		{
			world = new World();
			id = world.createPlayer().id;
		}
		super.create();


	}

	override public function update(elapsed:Float):Void
	{
		var su = Timer.stamp();
		if(Globals.online)
		{
			ws.process();
			if(state == null) return; // not ready
		}
		else
		{
			var b = Timer.stamp();
			state = world.update();
			worldUpdateTime = Timer.stamp() - b;
		}

		// handle move
		var player = state.objects.find(function(o) return o.id == id);
		if(player != null) 
		{
			// move player
			var mid = new FlxPoint(FlxG.width/2,FlxG.height/2);
			if(FlxG.mouse.pressed)
			{

				var dir = Math.atan2(FlxG.mouse.getScreenPosition().y - mid.y, FlxG.mouse.getScreenPosition().x - mid.x);
				if(Globals.online)
				{
					if(player.speed == 0) 
						ws.sendString(Serializer.run(StartMove));
					ws.sendString(Serializer.run(SetDirection(dir)));
				}
				else
				{
					player.speed = 3;
					player.dir = dir;
				}
			} 
			else 
			{
				if(Globals.online)
				{
					if(player.speed != 0)
						ws.sendString(Serializer.run(StopMove));
				}
				else
				{
					player.speed = 0;
				}
			}

			// update camera
			var scale = player.size / 40;
			
			if(FlxG.camera.zoom != scale)
			{
				flixel.tweens.FlxTween.tween(FlxG.camera, {zoom: 1/scale},.5);				
			}
		}
		var bo = Timer.stamp();
		for(object in state.objects) 
		{
			var s:FlxSprite;
			if(!sprites.exists(object.id))
			{
				trace(object);
				s = cast recycle(FlxSprite);
				if(object.id == id)
				{
					trace("PLAYER FOUND");
					s.makeGraphic(Std.int(object.size), Std.int(object.size), FlxColor.RED);
					FlxG.camera.follow(s);

				}else
					s.makeGraphic(Std.int(object.size), Std.int(object.size), FlxColor.fromInt(object.color + 0xFF000000));
				s.setPosition(object.x, object.y);
				add(s);
				sprites.set(object.id,s);

			}
			else
			{
				s = sprites.get(object.id);
				s.setPosition(object.x, object.y);
				flixel.tweens.FlxTween.tween(s,{x:object.x,y:object.y});
			}

			if(object.type == game.ObjectType.Player || object.type == game.ObjectType.Ai)
			{
				var scale = object.size / 40;
				if(s.scale.x != scale)
					flixel.tweens.FlxTween.tween(s.scale,{x:scale, y:scale},0.5);
			}
		}
		worldTreat = Timer.stamp()-bo;
		for(object in state.removed)
		{
			if(sprites.exists(object.id))
			{
				trace('removing ${object.id}');
				var s = sprites.get(object.id);
				s.kill();
				remove(s);
				sprites.remove(object.id);
			}else{
				trace('object ${object.id} not found');
			}
		}

		if(FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.switchState(new MenuState());
		}

		super.update(elapsed);
		stateUpdate = Timer.stamp() - su;
	}

	override public function destroy()
	{
		trace('destroying PlayState');
		if(ws != null)
		{
			ws.close();
			ws = null;
		}
		super.destroy();
	}
}
