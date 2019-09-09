# Data-exchange-protocol

## Usage

## Test

Smart contracts tests are allocated in the following directory: `test/contracts`

`ganache-cli` should be installed in order to run tests:
- Global installation:
```
npm install -g ganache-cli
```
- Local installation:
  - the package is included in `package.json`. Therefore by typing:
```
npm i
```
`ganache-cli` will be installed only for this repository

### Run test
open one terminal and run a local blockchain using `ganache-cli`:
```
ganache-cli
``` 
Default `ip:port` --> `127.0.0.1:8545`

trigger specific test with truffle:
```
truffle test ./test/contracts/#testName
```
--------
--------


## TODO
- merkle tree library
  - merkle tree off-chain structure
  - check merkle tree on-chain function

- comment smart contract
  - functions
  - parameters

- change `block.timestamp` for `block.number`

- review data types used in smart contract ( `bytes32` )
