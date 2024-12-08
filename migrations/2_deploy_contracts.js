const SnailMarket = artifacts.require("SnailMarket");

module.exports = function(deployer) {
    deployer.deploy(SnailMarket);
};
