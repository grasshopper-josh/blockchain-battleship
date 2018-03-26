pragma solidity ^0.4.19;

import "./Ownable.sol";

contract Battleboats is Ownable {
  
  struct PlayerState {
    uint[] attacks;
    uint[] hits;
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

    uint stateStarted;
    string gameState;

    address winner;
    string outcome;
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
  uint constant public MAX_BOARD_SIZE = 10;
  uint constant public MAX_GAME_LENGHT_IN_ROUNDS = 30;
  uint constant public MAX_WAIT_TIME_IN_MINUTES = 12 * 60 * 1 minutes;
  
  uint constant public TOURNAMENT_FEE = 3;
  uint constant public CANCELLATION_FEE = 1;

  string constant GAME_STATE_OPEN = "OPEN";
  string constant GAME_STATE_CANCELLED = "CANCELLED";

  string constant GAME_STATE_ATTACK = "ATTACK";
  string constant GAME_STATE_ATTACK_WAITING_P1 = "ATTACK_WAITING_P1";
  string constant GAME_STATE_ATTACK_WAITING_P2 = "ATTACK_WAITING_P2";

  string constant GAME_STATE_EVAL = "EVAL";
  string constant GAME_STATE_EVAL_WAITING_P1 = "EVAL_WAITING_P1";
  string constant GAME_STATE_EVAL_WAITING_P2 = "EVAL_WAITING_P2";

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
  event GameCreatedEvent(uint _gameId, uint _bet);
  event GameAttackStartedEvent(uint _gameId);
  event GameEvalStartedEvent(uint _gameId);
  event GameCancelledEvent(uint _gameId);


  /// @notice All you need to create a game is thye amount you want to bet.
  ///
  /// @dev PlayerOne will be the game 'owner'. When a game is started only one PlayerState is 
  /// created. If both player states are created, playerOns is carrying more of the game costs 
  /// than needed 
  ///
  /// @param _bet - Amount you are willing to bet
  /// @param _boardHash - The board hash is required before the game can be started. If this is  
  /// hash cannot be reproduced at the end of the game, you lose by default. 
  function createGame(uint _bet, uint _boardHash) payable public returns(uint) {
    
    require(_bet == msg.value);

    PlayerState memory playerOneState;
    playerOneState.boardHash = _boardHash;

    uint playerOneStateId = playerStates.push(playerOneState);
    
    Game memory newGame = Game({
      playerOne: msg.sender,
      playerTwo: 0x00000000,
      playerOneStateId: playerOneStateId,
      playerTwoStateId: 0,
      round:0,
      stateStarted: now,
      gameState: GAME_STATE_OPEN,
      winner: 0x00000000,
      outcome: GAME_OUTCOME_EMPTY,
      bet: _bet
    });

    uint gameId = games.push(newGame);
    playerGames[msg.sender].push(gameId);

    balanceOf[msg.sender] += _bet;
    
    GameCreatedEvent(gameId, _bet);
    return gameId;
  }

  /// @notice Join by providing a GameId
  ///
  /// @dev This should be changed to 'randomly' match up people. You should only have to input a 
  /// the maximum amount you are willing to bet. If not players cam n play against "themselfs" to 
  /// to boost their rankings.
  ///
  /// @param _gameId - 
  /// @param _boardHash - The board hash is required before the game can be started. If this is  
  /// hash cannot be reproduced at the end of the game, you lose by default. 
  function joinGame(uint _gameId, uint _boardHash) payable public {
    
    require(keccak256(games[_gameId].gameState) == keccak256(GAME_STATE_OPEN));
    require(games[_gameId].bet == msg.value);
    require(games[_gameId].playerOne != msg.sender);

    PlayerState memory playerTwoState;
    playerTwoState.boardHash = _boardHash;
    uint playerTwoStateId = playerStates.push(playerTwoState);

    Game storage game = games[_gameId];
    game.playerTwo = msg.sender;
    game.playerTwoStateId = playerTwoStateId;
    game.gameState = GAME_STATE_ATTACK;
    game.stateStarted = now;

    playerGames[msg.sender].push(_gameId);
    balanceOf[msg.sender] += msg.value;

    GameAttackStartedEvent(_gameId);
  }

  /// @notice Cancel a game to release funds. A 1% cancellation fee with be charged, which
  /// goes to the tournament fund.
  /// 
  /// @param _gameId - GameId for game that will be cancelled
  function cancelNewGame(uint _gameId) public onlyGameOwner(_gameId) {
    require(keccak256(games[_gameId].gameState) == keccak256(GAME_STATE_OPEN));

    uint amount = games[_gameId].bet;
    
    if (amount > 0) {

      uint cancellationFee = _computeCut(amount, CANCELLATION_FEE);
      msg.sender.transfer(amount - cancellationFee);
      balanceOf[msg.sender] -= amount;
      _payToTournamentFund(cancellationFee);

    }

    games[_gameId].gameState = GAME_STATE_CANCELLED;
    GameCancelledEvent(_gameId);
    
  }

  /// @notice Launch an attack on a position for a spesific game. A player is only allowed
  /// one attack per round :) Invalid positions will be recorded, but not taken into account
  /// during the scoring round.
  /// 
  /// @dev dev
  ///
  /// @param _gameId - GameId for game that will be cancelled
  /// @param _attackPosition - GameId for game that will be cancelled
  function attackPosition(uint _gameId, uint _attackPosition) public onlyGamePlayers(_gameId) {
    uint player = _playerOneOrplayerTwo(_gameId, msg.sender);
    
    require(
      keccak256(games[_gameId].gameState) == keccak256(GAME_STATE_ATTACK) || 
      keccak256(games[_gameId].gameState) == keccak256(GAME_STATE_ATTACK_WAITING_P1) ||
      keccak256(games[_gameId].gameState) == keccak256(GAME_STATE_ATTACK_WAITING_P2));

    // Safe to assume player is either 1 or 2, thanks to onlyGamePlayers modifier
    string memory stateUpdate;
    uint playerStateId;
    bool playerHasAttack = playerStates[playerStateId].attacks.length < games[_gameId].round;

    if (player == 1) {
      stateUpdate = GAME_STATE_ATTACK_WAITING_P2;
      playerStateId = games[_gameId].playerOneStateId;
    } else {
      stateUpdate = GAME_STATE_ATTACK_WAITING_P1;
      playerStateId = games[_gameId].playerTwoStateId;      
    }

    if (playerHasAttack) {

      playerStates[playerStateId].attacks.push(_attackPosition);

      if (keccak256(games[_gameId].gameState) == keccak256(GAME_STATE_ATTACK)) {
        games[_gameId].gameState = stateUpdate;
      } else {
        games[_gameId].gameState = GAME_STATE_EVAL;
        games[_gameId].stateStarted = now;
        GameEvalStartedEvent(_gameId);
      }
    }
    
  }

  /// @notice notice
  /// 
  /// @param _gameId - GameId for game that will be cancelled
  /// @param _attackPosition - GameId for game that will be cancelled
  /// @param _hit - GameId for game that will be cancelled
  function evaluateAttack(uint _gameId, uint _attackPosition, bool _hit) public onlyGamePlayers(_gameId) {
    uint player = _playerOneOrplayerTwo(_gameId, msg.sender);
    
    require(
      keccak256(games[_gameId].gameState) == keccak256(GAME_STATE_EVAL) || 
      keccak256(games[_gameId].gameState) == keccak256(GAME_STATE_EVAL_WAITING_P1) ||
      keccak256(games[_gameId].gameState) == keccak256(GAME_STATE_EVAL_WAITING_P2));
    
    uint playerStateId;

    if (player == 1 && keccak256(games[_gameId].gameState) != keccak256(GAME_STATE_EVAL_WAITING_P2)) {
      games[_gameId].gameState = GAME_STATE_EVAL_WAITING_P2;
      playerStateId = games[_gameId].playerTwoStateId;
      
      if (_hit) {
        playerStates[playerStateId].hits.push(_attackPosition);
      }

    } else if (player == 2 && keccak256(games[_gameId].gameState) != keccak256(GAME_STATE_EVAL_WAITING_P1)) {
      games[_gameId].gameState = GAME_STATE_EVAL_WAITING_P1;
      playerStateId = games[_gameId].playerOneStateId;
      
      if (_hit) {
        playerStates[playerStateId].hits.push(_attackPosition);
      }

    } else {
      games[_gameId].gameState = GAME_STATE_ATTACK;
      games[_gameId].stateStarted = now;
      GameAttackStartedEvent(_gameId);
    }

  }


  // ==============================================================================================
  // GAME FORWARDERS
  // ==============================================================================================

  // function forfeit(uint _gameId) public onlyGamePlayers(_gameId) {
  // }

  // function forceQuit(uint _gameId) public onlyGamePlayers(_gameId) {
  // }


  // ==============================================================================================
  // PUBLIC HELPERS
  // ==============================================================================================

  /// @notice This method MUST be used to calculate a board hash. Keep the inputs private and make
  /// sure not to change them. If the game cannot confirm your board hash at the end of the game,
  /// you loose by default.
  /// 
  /// @param _salt - This should be a unique string and will help protect the boardHash from being
  /// "brute-forced".
  /// @param _positions - The positions where boats are located. The order is not important, but
  /// the same order must be supplied at the end of the game to reporduce the hash. A position must
  /// be between 0 and 99. 0 <= position <= 99 
  function getHash(string _salt, uint[10] _positions) public pure returns(uint) {
    
    uint hash = uint(keccak256(_salt));

    for ( uint i = 0; i < _positions.length; i++) {
      hash = uint(keccak256(hash, _positions[i]));
    }

    return hash;
  }

  /// @notice This will help to make sure you are not providing an invalid set of positions and 
  /// be disqualified at the end of the game.
  /// 
  /// @param _positions - The positions where boats are located. The order is not important, but
  /// the same order must be supplied at the end of the game to reporduce the hash. A position must
  /// be between 0 and 99. 0 <= position <= 99
  function testBoardValidity(uint[10] _positions) public pure returns(bool) {

    uint maxPosition = (MAX_BOARD_SIZE * MAX_BOARD_SIZE) - 1;

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

  /// @dev NOTES HERE
  /// @param _amount - 
  function _payToTournamentFund(uint _amount) internal {
    balanceOf[tournamentFundAddress] += _amount;
    tournamentFund += _amount;
  }

  /// @dev Notes here
  /// @param _gameId - 
  /// @param _player - 
  function _playerOneOrplayerTwo(uint _gameId, address _player) internal view returns (uint) {
    
    if(games[_gameId].playerOne == _player) {
      return 1;
    } else if(games[_gameId].playerTwo == _player) {
      return 2;
    } else {
      return 0;
    }

  }

  // ==============================================================================================
  // MODIFIERS
  // ==============================================================================================

  modifier onlyGameOwner(uint _gameId) {
    require(games[_gameId].playerOne == msg.sender);
    _;
  }

  modifier onlyGamePlayers(uint _gameId) {
    require(games[_gameId].playerOne == msg.sender || games[_gameId].playerTwo == msg.sender);
    _;
  }

  // ==============================================================================================
  // ONLYOWNER
  // ==============================================================================================

  /// @notice notice
  /// @dev dev
  /// @param _newAddress - 
  function setTournamentFundAddress(address _newAddress) public onlyOwner {
    uint amount = balanceOf[tournamentFundAddress];
    balanceOf[tournamentFundAddress] = 0;
    balanceOf[_newAddress] = amount;
  }

  /// @notice notice
  /// @dev dev
  /// @param _to - 
  function withdrawTournamentFunds(address _to) public onlyOwner {
    uint amount = balanceOf[tournamentFundAddress];
    _to.transfer(amount);
    balanceOf[tournamentFundAddress] = 0;
  }

}