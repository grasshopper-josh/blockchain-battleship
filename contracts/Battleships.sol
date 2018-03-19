pragma solidity ^0.4.19;

import './Ownable.sol';

contract Battleships is Ownable {
	
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
		uint roundStarted;

		string gameState;
		address winner;
		uint outcome;
		uint bet;
  }

	// ==============================================================================================
	// GAME STATE
	// ==============================================================================================
	Game[] public games;
	PlayerState[] public playerStates;
	mapping(address => uint[]) public playerGames;

	// ==============================================================================================
	// GAME PARAMETERS 
	// ==============================================================================================
	uint constant public MAX_BAORD_SIZE = 10;
	uint constant public MAX_GAME_LENGHT_IN_ROUNDS = 30;
	uint constant public MAX_WAIT_TIME_IN_MINUTES = 12 * 60 * 1 minutes;
  
	uint constant public TOURNAMENT_FEE = 3;
	uint constant public CANCELLATION_FEE = 1;

	string constant GAME_STATE_OPEN = "OPEN";
	string constant GAME_STATE_LOADING = "LOADING";
	string constant GAME_STATE_INROUND = "INROUND";
	string constant GAME_STATE_WAITING_EVAL = "WAITING_EVAL";
	string constant GAME_STATE_GG = "GG";

	string constant GAME_OUTCOME_EMPTY = "EMPTY";
	string constant GAME_OUTCOME_WIN = "WIN";
	string constant GAME_OUTCOME_WIN_BY_DEFAULT = "WIN_BY_DEFAULT";
	string constant GAME_OUTCOME_WIN_BY_CHEAT = "WIN_BY_CHEAT";
	string constant GAME_OUTCOME_DRAW = "OPEN";
	string constant GAME_OUTCOME_BOTH_CHEAT = "BOTH_CHEAT";
	

	// ==============================================================================================
	// GAME FINANCES
	// ==============================================================================================
	address tournamentFundAddress = 0x00000000;
	uint public tournamentFund = 0;
	mapping(address => uint256) public balanceOf;

	// ==============================================================================================
	// GAME EVENTS
	// ==============================================================================================
	event NewGameAvailableEvent(uint _gameId, uint _bet);
	event GameJoinedEvent(uint _gameId);
	event GameRoundStartedEvent(uint _gameId);
	event GameCancelledEvent(uint _gameId);


	/// @notice
	/// @ dev 
	/// @param _bet - 
	function createGame(uint _bet) payable public returns(uint) {
		
		require(_bet == msg.value);

		PlayerState memory playerOneState;
		
		uint playerOneStateId = playerStates.push(playerOneState);
		
		Game memory newGame = Game({
			playerOne: msg.sender,
			playerTwo: 0x00000000,
			playerOneStateId: playerOneStateId,
			playerTwoStateId: 0,
			round:0,
			roundStarted: now,
			gameState: GAME_STATE_OPEN,
			winner: 0x00000000,
			outcome: GAME_OUTCOME_EMPTY,
			bet: _bet
		});

		uint gameId = games.push(newGame);
		playerGames[msg.sender].push(gameId);

		balanceOf[msg.sender] += _bet;
		
		NewGameAvailableEvent(gameId, _bet);
		return gameId;
	}

	/// @notice
	/// @ dev 
	/// @param _gameId - 
	function joinGame(uint _gameId) payable public {
		
		require(keccak256(games[_gameId].gameState) == keccak256(GAME_STATE_OPEN));
		require(games[_gameId].bet == msg.value);

		PlayerState memory playerTwoState;
		uint playerTwoStateId = playerStates.push(playerTwoState);

		Game storage game = games[_gameId];
		game.playerTwo = msg.sender;
		game.playerTwoStateId = playerTwoStateId;
		game.gameState = GAME_STATE_LOADING;

		playerGames[msg.sender].push(_gameId);
		balanceOf[msg.sender] += msg.value;

		GameJoinedEvent(_gameId);
	}

	/// @notice
	/// @ dev 
	/// @param _gameId - 
	/// @param _boardHash - 
	function updateLoadingState(uint _gameId, uint _boardHash) public onlyGamePlayers(_gameId) {
		require(keccak256(games[_gameId].gameState) == keccak256(GAME_STATE_LOADING));

		PlayerState storage playerOneState = playerStates[games[_gameId].playerOneStateId];
		PlayerState storage playerTwoState = playerStates[games[_gameId].playerOneStateId];

		if ( msg.sender == games[_gameId].playerOne ) {
			playerOneState.boardHash = _boardHash;
		} else {
			playerTwoState.boardHash = _boardHash;
		}

		if (playerOneState.boardHash != 0 && playerOneState.boardHash != 0) {
			games[_gameId].round = 1;
			games[_gameId].gameState = GAME_STATE_INROUND;
			GameRoundStartedEvent(_gameId);
		}
	}

	/// @notice
	/// @ dev 
	/// @param _gameId - 
	function cancelNewGame(uint _gameId) public onlyGameOwner(_gameId) {
		require(keccak256(games[_gameId].gameState) == keccak256(GAME_STATE_OPEN));

		uint amount = games[_gameId].bet;
		balanceOf[msg.sender] -= amount;
		
		if (amount > 0) {
				if (msg.sender.send(_computeCut(amount, 100 - CANCELLATION_FEE))) {
						_payToTournamentFund(_computeCut(amount, CANCELLATION_FEE));
						GameCancelledEvent(_gameId);
				} else {
						balanceOf[msg.sender] = amount;
				}
		}
		
	}

	/// @notice
	/// @ dev 
	/// @param _salt - 
	/// @param _positions - 
	function getHash(string _salt, uint[10] _positions) public pure returns(uint) {
		
		uint hash = uint(keccak256(_salt));

		for ( uint i = 0; i < _positions.length; i++) {
			hash = uint(keccak256(hash + _positions[i]));
		}

		return hash;
	}

	/// @notice
	/// @ dev 
	/// @param _positions - 
	function testBoardValidity(uint[10] _positions) public view returns(bool) {

		uint maxPosition = (MAX_BAORD_SIZE * MAX_BAORD_SIZE) - 1;

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


	// ==============================================================================================
	// PRIVATE METHODS
	// ==============================================================================================

	/// @dev Computes cut
	/// @param _amount - Sale price of NFT.
	/// @param _cutPercentage - 0 - 100
	function _computeCut(uint _amount, uint _cutPercentage) internal pure returns (uint) {
		// NOTE: We don't use SafeMath (or similar) in this function because
		//  all of our entry functions carefully cap the maximum values for
		//  currency (at 128-bits), and ownerCut <= 10000 (see the require()
		//  statement in the ClockAuction constructor). The result of this
		//  function is always guaranteed to be <= _price.
		uint cut = _cutPercentage * 100;
		return _amount * cut / 10000;
	}

	/// @ dev 
	/// @param _amount - 
	function _payToTournamentFund(uint _amount) internal {
		balanceOf[tournamentFundAddress] += _amount;
		tournamentFund += _amount;
	}

	// ==============================================================================================
	// MODIFIERS
	// ==============================================================================================

	/// @ dev 
	/// @param _gameId - 
	modifier onlyGameOwner(uint _gameId) {
		require(games[_gameId].playerOne == msg.sender);
		_;
	}

	/// @ dev 
	/// @param _gameId - 
	modifier onlyGamePlayers(uint _gameId) {
		require(games[_gameId].playerOne == msg.sender || games[_gameId].playerTwo == msg.sender);
		_;
	}

	// ==============================================================================================
	// ONLYOWNER
	// ==============================================================================================

	/// @notice
	/// @ dev 
	/// @param _newAddress - 
	function setTournamentFundAddress(address _newAddress) public onlyOwner {
		uint amount = balanceOf[tournamentFundAddress];
		balanceOf[tournamentFundAddress] = 0;
		balanceOf[_newAddress] = amount;
	}

	/// @notice
	/// @ dev 
	/// @param _to - 
	function withdrawTournamentFunds(address _to) public onlyOwner {
		uint amount = balanceOf[tournamentFundAddress];
		balanceOf[tournamentFundAddress] = 0;
		if (!_to.send(amount))
			balanceOf[tournamentFundAddress] = amount;
	}

}