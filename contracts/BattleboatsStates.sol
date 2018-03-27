pragma solidity ^0.4.19;

contract BattleboatsStates {

	struct PlayerState {
    uint[] attacks;
    uint[] hits;
    uint boardHash;
    uint[10] boatPositions;
    string salt;
    uint score;
    bool cheated;
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
}