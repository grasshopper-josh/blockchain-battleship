pragma solidity ^0.4.19;

contract Battleships {
	
	struct PlayerState {
		uint[] moves;
		uint boardHash;
		uint[10] boatPositions;
		string salt;
	}

	struct Game {
		address playerOne;
		address playerTwo;
    
		uint playerOneStateId;
		uint playerTwoStateId;
		
		uint round;

		string gameState; // States: OPEN, LOADING, INROUND, WAITINGEVAL, GG
		address winner;
		string outcome; 	// DRAW, WIN, WIN_DEFAULT, DEFAULT
  }

	// Game Constants
	uint public maxBoardSize = 10;
	uint public maxGameLengthInRounds = 30;
	uint public maxWaitTimeInHours = 12;

	// Game State
	Game[] public games;
	PlayerState[] public playerStates;
	mapping(address => uint[]) public playerGames;

	// Funds
	uint public tournamentFund = 0;
	

	// Game Events
	event NewGameAvailableEvent(uint _gameId);
	event GameJoinedEvent(uint _gameId);
	event GameRoundStartedEvent(uint _gameId);


	function createGame() public returns(uint) {
		
		PlayerState memory playerOneState;
		
		uint playerOneStateId = playerStates.push(playerOneState);
		
		Game memory newGame = Game({
			playerOne: msg.sender,
			playerTwo: 0x00000000,
			playerOneStateId: playerOneStateId,
			playerTwoStateId: 0,
			round:0,
			gameState:"OPEN",
			winner: 0x00000000,
			outcome: ""
		});

		uint gameId = games.push(newGame);
		playerGames[msg.sender].push(gameId);
		
		NewGameAvailableEvent(gameId);
		return gameId;
	}

	function joinGame(uint _gameId) public {
		
		require(keccak256(games[_gameId].gameState) == keccak256("OPEN"));
		
		PlayerState memory playerTwoState;
		uint playerTwoStateId = playerStates.push(playerTwoState);

		Game storage game = games[_gameId];
		game.playerTwo = msg.sender;
		game.playerTwoStateId = playerTwoStateId;
		game.gameState = "LOADING";

		playerGames[msg.sender].push(_gameId);

		GameJoinedEvent(_gameId);
	}

	function updateLoadingState(uint _gameId, uint _boardHash) public {
		require(keccak256(games[_gameId].gameState) == keccak256("LOADING"));
		require(msg.sender == games[_gameId].playerOne || msg.sender == games[_gameId].playerTwo);

		PlayerState storage playerOneState = playerStates[games[_gameId].playerOneStateId];
		PlayerState storage playerTwoState = playerStates[games[_gameId].playerOneStateId];

		if ( msg.sender == games[_gameId].playerOne ) {
			playerOneState.boardHash = _boardHash;
		} else {
			playerTwoState.boardHash = _boardHash;
		}

		if (playerOneState.boardHash != 0 && playerOneState.boardHash != 0) {
			games[_gameId].round = 1;
			games[_gameId].gameState = "INROUND";
			GameRoundStartedEvent(_gameId);
		}
	}

	// A position must be between zero and 99
	function getHash(string _salt, uint[10] _positions) public pure returns(uint) {
		
		uint hash = uint(keccak256(_salt));

		for ( uint i = 0; i < _positions.length; i++) {
			hash = uint(keccak256(hash + _positions[i]));
		}

		return hash;
	}

	function testBoardValidity(uint[10] _positions) public view returns(bool) {

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