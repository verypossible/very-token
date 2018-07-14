const fs = require('fs');
const Web3 = require('web3');
const solc = require('solc');

// For localhost
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
web3.eth.getCoinbase().then((account) => {
  unlockAccount(account);
  const src = loadSol();
  // web3.eth.getGasPrice().then((gas) => console.log('AVG: ' + gas));
  web3.eth.estimateGas({ data: src.code }).then((gasEstimate) => {
    const VeryToken = new web3.eth.Contract(src.abi, null, {
      data: src.code,
      gas: gasEstimate,
      from: account,
    });

    VeryToken.deploy({
      arguments: ['100', 'ERIC', 'ERIC'],
    }).send().then(console.log).catch(console.log);
  });
  // console.log(VeryToken);
  // VeryToken.deploy().estimateGas().then(console.log);
});

function loadSol() {
  const inputs = {
      'VeryToken.sol': fs.readFileSync('./contracts/ERC223/VeryToken.sol').toString(),
  };

  // Assumes imported files are in the same folder/local path
  function findImports(path) {
      return {
          'contents': fs.readFileSync('./contracts/ERC223/' + path).toString()
      }
  }
  const compiled = solc.compile({ sources: inputs }, 1, findImports);
  const abi = JSON.parse(compiled.contracts['VeryToken.sol:VeryToken'].interface);
  const code = '0x' + compiled.contracts['VeryToken.sol:VeryToken'].bytecode;
  return { abi, code };
}

function unlockAccount(address) {
  console.log("Unlocking coinbase account");
  const password = process.env.PASS;
  try {
    web3.eth.personal.unlockAccount(address, password);
  } catch(e) {
    console.log(e);
    return;
  }
  console.log('Successfully unlocked account');
}
