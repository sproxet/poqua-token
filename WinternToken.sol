pragma solidity ^0.4.19;

library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}


contract ERC20Interface {
  function totalSupply() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);
  function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract WinternToken is ERC20Interface {
  using SafeMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint public _totalSupply;

  event KeyAdded(address indexed tokenOwner, bytes32 pubKey);
  event Authorized(address indexed from, address indexed to, uint tokens);

  mapping(address => TokenHolder) holders;
  struct TokenHolder {
    uint balance;
    bytes32 pubKey;
    address authorizedRecipient;
    uint authorizedAmount;
    uint nonce;
  }

  constructor() public {
    symbol = "WIN";
    name = "WinternToken";
    decimals = 18;
    _totalSupply = 1000000 * 10**uint(decimals);
    holders[msg.sender].balance = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function totalSupply() public constant returns (uint) {
    return _totalSupply - holders[address(0)].balance;
  }

  function balanceOf(address tokenOwner) public constant returns (uint balance) {
    return holders[tokenOwner].balance;
  }

  function nonceOf(address tokenOwner) public constant returns (uint nonce) {
    return holders[tokenOwner].nonce;
  }

  function currentPubKeyOf(address tokenOwner) public constant returns (bytes32 pubKey) {
    return holders[tokenOwner].pubKey;
  }

  function authorizedRecipientOf(address tokenOwner) public constant returns (address authorizedRecipient) {
    return holders[tokenOwner].authorizedRecipient;
  }

  function authorizedAmountOf(address tokenOwner) public constant returns (uint authorizedAmount) {
    return holders[tokenOwner].authorizedAmount;
  }

  function transfer(address to, uint tokens) public returns (bool success) {
    require(holders[msg.sender].balance > tokens);

    if (holders[msg.sender].pubKey != 0x0000000000000000000000000000000000000000000000000000000000000000) {
      require(holders[msg.sender].authorizedRecipient == to);
      require(holders[msg.sender].authorizedAmount == tokens);

      holders[msg.sender].authorizedRecipient = address(0);
      holders[msg.sender].authorizedAmount = 0;
    }

    holders[msg.sender].balance = holders[msg.sender].balance.sub(tokens);
    holders[to].balance = holders[to].balance.add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }

  function addKey(bytes32 pubKey) public returns (bool success) {
    require(holders[msg.sender].pubKey == 0x0000000000000000000000000000000000000000000000000000000000000000);

    holders[msg.sender].pubKey = pubKey;
    emit KeyAdded(msg.sender, pubKey);
    return true;
  }

  function authorize(address to, uint tokens, bytes20[67] sig, bytes32 newPubKey) public returns (bool success) {
    require(verify(sha256(abi.encodePacked(to, tokens, newPubKey)), sig, holders[msg.sender].pubKey));

    holders[msg.sender].authorizedRecipient = to;
    holders[msg.sender].authorizedAmount = tokens;
    holders[msg.sender].pubKey = newPubKey;
    holders[msg.sender].nonce += 1; // nonce is too large to wrap around, and it's not an issue for the contract even if it does.
    emit KeyAdded(msg.sender, newPubKey);
    emit Authorized(msg.sender, to, tokens);
    return true;
  }

  function verify(bytes32 h_msg, bytes20[67] sig, bytes32 pubKey) private pure returns (bool valid) {
    // Calculate checksum.
    uint16 cs = 960;
    for (uint8 n = 0; n < 64; n += 1) {
      if (n % 2 == 0) {
        cs -= uint16(h_msg[n/2] >> 4);
      } else {
        cs -= uint16(h_msg[n/2] & 0xf);
      }
    }
    cs = cs << 4;

    // Recalculate full public key.

    bytes20[67] memory z;

    for (uint8 i = 0; i < 67; i += 1) {
      // a = 15 - coef(v, i, 4)
      uint8 a;
      if (i < 64) {
        if (i % 2 == 0) {
          a = 15 - uint8(h_msg[i/2] >> 4);
        } else {
          a = 15 - uint8(h_msg[i/2] & 0xf);
        }
      } else {
        if (i == 64) {
          a = 15 - uint8(cs >> 12);
        }
        if (i == 65) {
          a = 15 - uint8((cs >> 8) & 0xf);
        }
        if (i == 66) {
          a = 15 - uint8((cs >> 4) & 0xf);
        }
        if (i == 67) {
          a = 15 - uint8(cs & 0xf);
        }
      }

      z[i] = sig[i];
      for (uint8 _ = 0; _ < a; _ += 1) {
        z[i] = bytes20(sha256(abi.encodePacked(z[i])));
      }
    }

    // Hash full public key and compare the hash with (the hash) pubKey.
    return sha256(abi.encodePacked(z)) == pubKey;
  }


  function approve(address, uint) public returns (bool) { return false; }
  function transferFrom(address, address, uint) public returns (bool) { return false; }
  function allowance(address, address) public constant returns (uint) { return 0; }
}
