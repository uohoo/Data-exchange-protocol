/* global artifacts */
/* global contract */
/* global web3 */
/* global BigInt */

const chai = require('chai');
const { smt } = require('circomlib');
// const crypto = require("crypto");

const { expect } = chai;
const DataMarket = artifacts.require('../contracts/test/DataMarketTest.sol');
const poseidonUnit = require('../../node_modules/circomlib/src/poseidon_gencontract.js');

contract('Data market', (accounts) => {
  const {
    0: owner,
    1: buyer,
    2: seller,
  } = accounts;

  const initialAmount = 100;
  let insDataMarket;
  let insPoseidonUnit;
  let cryptogramsTree;
  let keyTree;

  const n = '0x0000000000000000000000000000000000000000000000000000000000000001';
  const p = 1;
  const rootKeys = '0x0000000000000000000000000000000000000000000000000000000000000001';
  const rootCryptograms = '0x0000000000000000000000000000000000000000000000000000000000000002';

  before(async () => {
    // Deploy poseidon
    const C = new web3.eth.Contract(poseidonUnit.abi);
    insPoseidonUnit = await C.deploy({ data: poseidonUnit.createCode() })
      .send({ gas: 2500000, from: owner });

    // initialize smt trees
    cryptogramsTree = smt.newMemEmptyTrie();
    keyTree = smt.newMemEmptyTrie();
  });

  it('Seller creates cryptograms and its tree', async () => {

  });

  it('Seller creates keys and its tree', async () => {

  });

  it('Seller deploy data market smart contract', async () => {
    // Deploy data market
    insDataMarket = await DataMarket.new(n, p, rootKeys, rootCryptograms, insPoseidonUnit._address, { from: seller });
  });
});
