pragma solidity ^0.4.19;

contract Battleships {
	
	struct PlayerState {
		string[] moves;
		string[] hits;
		uint boardHash;
		uint[10] boardPositions;
		string salt;
	}

	struct Game {
		address playerOne;
		address playerTwo;
    
		uint playerOneStateId;
		uint playerTwoStateId;
		
		string gameState; // States: OPEN, LOADING, INROUND, WAITINGEVAL, GG
		address winner;
  }

	event NewGameAvailableEvent(uint _gameId);
	event GameJoinedEvent(uint _gameId);

	uint public maxBoardSize = 10;

	Game[] public games;
	PlayerState[] public playerStates;

	mapping(address => uint[]) public playerGames;

	function createGame() public returns(uint) {
		
		PlayerState memory playerOneState = PlayerState(new string[](0),new string[](0),0,"");
		PlayerState memory playerTwoState = PlayerState(new string[](0),new string[](0),0,"");

		uint playerOneStateId = playerStates.push(playerOneState);
		uint playerTwoStateId = playerStates.push(playerTwoState);

		Game memory newGame = Game(msg.sender, 0x00000000, playerOneStateId,playerTwoStateId,"OPEN", 0x00000000);

		uint gameId = games.push(newGame);
		playerGames[msg.sender].push(gameId);
		
		NewGameAvailableEvent(gameId);
		return gameId;
	}

	function joinGame(uint _gameId) public {
		
		require(keccak256(games[_gameId].gameState) == keccak256("OPEN"));
		
		Game storage game = games[_gameId];
		game.playerTwo = msg.sender;
		game.gameState = "LOADING";

		GameJoinedEvent(_gameId);
	}

	function updateLoadingState(uint _gameId, uint _boardHash) public {
		require(keccak256(games[_gameId].gameState) == keccak256("LOADING"));
	}

	// A position must be between zero and 99
	function getHash(string _salt, uint[10] _positions) public pure returns(uint) {
		
		uint hash = uint(keccak256(_salt));

		for ( uint i = 0; i < _positions.length; i++) {
			hash = uint(keccak256(hash + _positions[i]));
		}

		return hash;
	}

	function testBoardValidity(uint[10] _positions) public pure returns(bool) {

		uint maxPosition = (maxBoardSize * maxBoardSize) - 1;

		for ( uint i = 0; i < _positions.length; i++) {
			uint count = 0;
			
			if (_positions[i] > maxPosition) {
				return false;
			}

			for ( uint j = 0; i < _positions.length; i++) {
				if (_positions[i] == _positions[j]) {
					count++;
				}
			}

			if (count != 1) {
				return false;
			}
		}

		return true;
	}

}