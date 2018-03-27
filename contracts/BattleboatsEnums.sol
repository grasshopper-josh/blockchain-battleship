pragma solidity ^0.4.19;

contract BattleboatsEnums {

  uint constant public MAX_BOARD_SIZE = 10;
  uint constant public MAX_GAME_LENGHT_IN_ROUNDS = 30;
  uint constant public MAX_WAIT_TIME_IN_MINUTES = 12 * 60 * 1 minutes;
  
  uint constant public TOTAL_LOSS = 100;
  uint constant public TOURNAMENT_FEE = 3;
  uint constant public CANCELLATION_FEE = 1;

  string constant public GAME_STATE_OPEN = "OPEN";
  string constant public GAME_STATE_CANCELLED = "CANCELLED";

  string constant public GAME_STATE_ATTACK = "ATTACK";
  string constant public GAME_STATE_ATTACK_WAITING_P1 = "ATTACK_WAITING_P1";
  string constant public GAME_STATE_ATTACK_WAITING_P2 = "ATTACK_WAITING_P2";

  string constant public GAME_STATE_EVAL = "EVAL";
  string constant public GAME_STATE_EVAL_WAITING_P1 = "EVAL_WAITING_P1";
  string constant public GAME_STATE_EVAL_WAITING_P2 = "EVAL_WAITING_P2";

  string constant public GAME_STATE_REVEAL = "REVEAL";
  string constant public GAME_STATE_REVEAL_WAITING_P1 = "REVEAL_WAITING_P1";
  string constant public GAME_STATE_REVEAL_WAITING_P2 = "REVEAL_WAITING_P2";

  string constant public GAME_STATE_GG = "GG";

  string constant public GAME_OUTCOME_EMPTY = "EMPTY";
  string constant public GAME_OUTCOME_WIN = "WIN";
  string constant public GAME_OUTCOME_DRAW = "DRAW";
  string constant public GAME_OUTCOME_TOTAL_LOSS = "TOTAL_LOSS";
}