const Battleboats = artifacts.require("./Battleboats.sol");

let emptyAddress = 0x0000000000000000000000000000000000000000;
let testHash = 4.1484356051023654579293778418796297254962059416686134302481335945881743918214e+76;
let bet = 15; // Wei

contract('JS: Game Joining', function (accounts) {

	let bb;
	before(function () {

		return Battleboats.deployed()
			.then(function (instance) {
				bb = instance;
				return bb.createGame(bet, testHash, { value: bet, from: accounts[0] });
			})
	});

	it("There should be a game", function () {

		return bb.games.call(0)
			.then(function (game) {
				assert.equal(accounts[0], game[0].valueOf(), "Player one does not match");
				assert.equal(emptyAddress, game[1].valueOf(), "Player one does not match");
				assert.equal("OPEN", game[6].valueOf(), "Game must start in OPEN state");
				assert.equal(bet, game[9].valueOf(), "Game bet not set");
			});
	});


});
