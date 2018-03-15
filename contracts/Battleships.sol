pragma solidity ^0.4.17;

contract Battleships {
	
	struct Player {
		address player;
		string[] moves;
		string[] hits;
		uint boardHash;
		string board;
	}

	struct Game {
    Player playerOne;
		Player playerTwo;
		string gameState; // States: open, loading, inRound, waitingEvaluation, gg
		address winner;
  }

	event NewGameAvailableEvent(uint _gameId);
	event GameJoinedEvent(uint _gameId);

	Game[] public games;
	mapping(address => uint[]) public playerGames;

	function createGame() public returns(uint) {
		// TODO Lockup funds
		
		Player memory pO = Player(msg.sender,new string[](0),new string[](0),0,"");
		Player memory pT = Player(0x00000000,new string[](0),new string[](0),0,"");
		Game memory newGame = Game(pO,pT,"open", 0x00000000);
		
		newGame.gameState = "open";
		newGame.playerOne.player = msg.sender; 

		uint gameId = games.push(newGame);
		playerGames[msg.sender].push(gameId);
		emit NewGameAvailableEvent(gameId);
		return gameId;
	}

	function joinGame(uint _gameId) {
		
		require(keccak256(games[_gameId].gameState) == keccak256("open"));
		
		Game storage game = games[_gameId];
		game.playerTwo.player = msg.sender;
		game.gameState = "loading";

		emit GameJoinedEvent(_gameId);
	}

	function getHash(string board) public pure returns(uint) {
		return uint(keccak256(board));
	}


	// function getWinner(Player playerOne, Player playerTwo) private returns(address, string) {
	// 	return 
	// }


}