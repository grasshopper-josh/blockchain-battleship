const Battleboats = artifacts.require("./Battleboats.sol");

contract('JS: Contract Basics', function (accounts) {

	it("Game has owner", function () {

		return Battleboats.deployed()
			.then(function (instance) {
				return instance.owner.call();
			})
			.then(function (owner) {
				assert.equal(accounts[0], owner, "Game owner does not match");
			});
	});


});
