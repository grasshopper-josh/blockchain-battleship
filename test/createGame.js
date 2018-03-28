const Battleboats = artifacts.require("./Battleboats.sol");

contract('JS: Test initial state', function (accounts) {

	it("all balances should be zero", function () {
		
		return Battleboats.deployed()
		.then(function (instance) {
			
			let account = accounts[0];
			let balance = instance.balanceOf[account];
			let claimableFunds = instance.balanceOfClaimableFunds[account];

			// return instance.getBalance.call(accounts[0]);
			assert.equal(balance.valueOf(), 0, "Locked up funds should be zero");
			assert.equal(claimableFunds.valueOf(), 0, "Claimable funds should be zero");
			
		
		});

	});


});