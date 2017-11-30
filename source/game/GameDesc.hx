package game;

@:keep
typedef GameDesc =
{
    var name:String;
    var host:String;
    var port:Int;
    var playerNumber:Int;
    var maxPlayer:Int;
    var lastUpdateTime:Float;
}
