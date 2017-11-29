package mp;

import game.*;

// sent from server to client
enum MasterMessage {
	GList(list:Array<GameDesc>);
	Registered;
	Updated;
}