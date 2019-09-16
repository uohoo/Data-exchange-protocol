pragma  solidity ^0.5.0;

import "../DataMarket.sol";

contract DataMarketTest is DataMarket {

  constructor( uint256 _n, uint256 _p, bytes32 _MRC, bytes32 _MRK, address _poseidonAddress)
    DataMarket(_n, _p, _MRC, _MRK, _poseidonAddress) public {}

  uint public blockNumber;

  function getBlockNumber() public view returns (uint) {
    return blockNumber;
  }

  function setBlockNumber(uint bn) public {
    blockNumber = bn;
  }
}