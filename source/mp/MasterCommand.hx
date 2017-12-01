package mp;

// sent from client to server
@:keep
enum MasterCommand
{
	List;
	Register(name:String, port:Int, playerNumber:Int, maxPlayer:Int);
	Update(playerNumber:Int,maxPlayer:Int);
}