package mp;

// sent from client to server
enum MasterCommand
{
	List;
	Register(name:String,playerNumber:Int,maxPlayer:Int);
	Update(playerNumber:Int,maxPlayer:Int);
}