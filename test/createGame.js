const Battleboats = artifacts.require("./Battleboats.sol");

let emptyAddress = 0x0000000000000000000000000000000000000000;
let testHash = 4.1484356051023654579293778418796297254962059416686134302481335945881743918214e+76;
let bet = 15; // Wei

contract('JS: Game Creation', function (accounts) {

	it("Game Creation", function () {
		let bb;

		return Battleboats.deployed()
			.then(function (instance) {
				bb = instance;
				return bb.createGame(bet, testHash, {value: bet, from: accounts[0]});
			})
			.then(function (gameId) {
				return bb.games.call(gameId-1);
			})
			.then(function (game) {
				assert.equal(accounts[0], game[0].valueOf(), "Player one does not match");
				assert.equal(emptyAddress, game[1].valueOf(), "Player two is not empty");
				assert.equal("OPEN", game[6].valueOf(), "Game must start in OPEN state");
				assert.equal(bet, game[9].valueOf(), "Game bet not set");
			});
	});

	it("Game Creation Bet + msg.value mismatch", function () {
		return Battleboats.deployed()
			.then(function (instance) {
				return instance.createGame(bet+1, testHash, {value: bet, from: accounts[0]});
			})
			.then(function (gameId) {
				assert.fail('Expected throw not received');
			})
			.catch(function(error) {
				assert(true);
			});
	});

});
