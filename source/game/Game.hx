package game;

import game.*;

class game
{
    public var world(get,null):World;
    public var maxPlayer:Int;

    public function new(maxPlayerAllowed:Int)
    {
        maxPlayer = maxPlayerAllowed;
        world = new World();
    }
}