pragma solidity ^0.4.24;

import 'SafeMath.sol';
import 'ERC20.sol';
import 'ERC223.sol';
import 'ContractReceiver.sol';
import 'Owned.sol';

contract VeryToken is owned, ERC20, ERC223 {
  using SafeMath for uint;

  string name;
  string symbol;
  uint256 totalSupply;
  uint256 buyPrice = 0;
  // 18 decimals is the strongly suggested default, avoid changing it
  uint8 decimals = 18;

  // this created an array with all balances
  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowances;

  /* initializes contract with initial supply tokens to the creator of the
  contract */
  function VeryToken(uint256 initialSupply, string tokenName, string tokenSymbol) public {
    name = tokenName;
    symbol = tokenSymbol;
    tokenSupply = initialSupply * 10 ** uint256(_decimals);
    balances[msg.sender] = totalSupply; // give creator all initial tokens
  }

  function balanceOf(address who) public view returns (uint256) {
    return balances[who];
  }

  function name() public view returns (string) {
    return name;
  }

  function symbol() public view returns (string) {
    return symbol;
  }

  function decimals() public view returns (uint8) {
    return decimals;
  }

  function totalSupply() public view returns (string) {
    return totalSupply;
  }

  function setPrices(uint256 newBuyPrice) onlyOwner public {
    buyPrice = newBuyPrice;
  }

  function buy() payable public {
    uint amount = msg.value / buyPrice;               // calculates the amount
    _transfer(this, msg.sender, amount);              // makes the transfers
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= allowances[_from][msg.sender]);     // Check allowance
    allowances[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
     return allowances[_owner][_spender];
   }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowances[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  // function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
    if (isContract(_to)) {
      if (balanceOf(msg.sender) < _value) {
        revert();
      }

      balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
      balances[_to] = SafeMath.add(balanceOf(_to), _value);
      assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
      emit Transfer(msg.sender, _to, _value, _data);
      return true;
    }

    return transferToAddress(_to, _value, _data);
  }

  // function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
    _transfer(msg.sender, _to, _value, empty);
  }

  // function that is called when transaction target is an address .
  function transfer(address _to, uint256 _value) public returns (bool success) {
    // standard function transfer similar to ERC20 transfer with no _data .
    // added due to backwards compatibility reasons .
    bytes memory empty;
    _transfer(msg.sender, _to, _value, empty);
  }

  // assemble the given address bytecode. If bytecode exists then the _addr is a contract .
  function isContract(address _addr) private view returns (bool is_contract) {
    uint length;
    assembly {
      // retrieve the size of the code on target address, this needs assembly .
      length := extcodesize(_addr)
    }

    return (length > 0);
  }

  function _transfer(address _from, address _to, uint _value, bytes _data) private returns (bool success) {
    if (isContract(_to)) {
      return transferToContract(_from, _to, _value, _data);
    }

    return transferToAddress(_from, _to, _value, _data);
  }

  // function that is called when transaction target is an address .
  function transferToAddress(address _from, address _to, uint _value, bytes _data) private returns (bool success) {
    // prevent transfer to 0x0 .
    if (_to == 0x0) {
      revert();
    }

    if (balanceOf(_from) < _value) {
      revert();
    }

    balances[_from] = SafeMath.sub(balanceOf(_from), _value);
    balances[_to] = SafeMath.add(balanceOf(_to), _value);
    emit Transfer(_from, _to, _value, _data);

    return true;
  }

  //function that is called when transaction target is a contract .
  function transferToContract(address _from, address _to, uint _value, bytes _data) private returns (bool success) {
    // prevent transfer to 0x0 .
    if (_to == 0x0) {
      revert();
    }

    if (balanceOf(_from) < _value) {
      revert();
    }

    balances[_from] = SafeMath.sub(balanceOf(_from), _value);
    balances[_to] = SafeMath.add(balanceOf(_to), _value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(_from, _value, _data);
    emit Transfer(_from, _to, _value, _data);

    return true;
  }
}
