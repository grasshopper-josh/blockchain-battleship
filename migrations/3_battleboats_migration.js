var Battleboats = artifacts.require("./Battleboats.sol");

module.exports = function (deployer) {
	deployer.deploy(Battleboats, {gas:6721975});
};
