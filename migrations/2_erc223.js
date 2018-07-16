const Web3 = require('web3');
const TruffleConfig = require('../truffle');
const VeryToken = artifacts.require("./VeryToken.sol");

module.exports = function(deployer, network, addresses) {
  const config = TruffleConfig.networks[network];
  console.log('>> Running migration');

  if (process.env.PASS) {
    const web3 = new Web3(new Web3.providers.HttpProvider('http://' + config.host + ':' + config.port));

    console.log('>> Unlocking account ' + config.from);
    web3.eth.personal.unlockAccount(config.from, process.env.PASS, 36000);
  }

  console.log('>> Deploying migration');
  deployer.deploy(VeryToken, 100000, "EROCK", "ERI");
};
