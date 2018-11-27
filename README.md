PoQua Token Contract
====================

This is a Solidty smart contract implementing PoquaToken, a quantum-secure ERC20 token.
Signature and key generation is not part of this contract; you will need to use a modified version of the `winternitz`
crate for that.

Initializing the Contract
-------------------------

Once a contract is initialized, all PoQua tokens will be sent to the initializer.

Initializing an Address
-----------------------

In order for an address to be quantum-secure, it must first be initialized with the `addKey` function. This function
must be called with a 32-bit LDWM public key.

Sending Funds
-------------

If an address has not been initialized, you may call `transfer` as specified in ERC20 and it will work. `approve`,
`transferFrom`, and `allowance` are not currently supported.

If an address has been initialized, you must call the `authorize` function prior to calling `transfer`. The arguments
to `authorize` are `authorize(address to, uint tokens, bytes20[67] sig, bytes32 newPubKey)`. Note that in the Ethereum
ABI, each element of the `bytes20[67]` array `sig` must be padded to 32 bytes. This is not relevant if you use a library
whuich supports passing arrays. Also note that `newPubKey` must be a new, never-before used key; reusing LDWM keys is
insecure.

After a successful `authorize` call is made, `transfer` may be called as usual, only once, and only with the exact
arguments supplied to `authorize`.

Getting Information
-------------------

`nonceOf(address)` will return the number of `authorize` calls address has made.
`currentPubkeyOf(address)` will return the key from which a signature must be made for `authorize` to be successful.
`authorizedAmountOf(address)` will return the amount that must be sent for a `transfer` to be successful.
`authorizedRecipientOf(address)` will return the recipient that must be sent for a `transfer` to be successful.

ERC20 events are sent as normal. Additionally, there is the `KeyAdded(address indexed tokenOwner, bytes32 pubKey)`
event, which is sent whenever a key is added (in `addKey` or `authorize`), and `Authorized(address indexed from, address indexed to, uint tokens)`,
which occurs when a successful `authorize` call is made. 