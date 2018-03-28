var A = artifacts.require("./BattleboatsEnums.sol");
var B = artifacts.require("./BattleboatsStates.sol");

module.exports = function (deployer) {
	deployer.deploy(A);
	deployer.deploy(B);
};
