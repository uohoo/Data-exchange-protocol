/* global artifacts */
/* global contract */

const chai = require('chai');

const { expect } = chai;
const DataMarket = artifacts.require('../contracts/DataMarket.sol');

contract('Data market', (accounts) => {
  const {
    0: owner,
    1: buyer,
    2: seller,
  } = accounts;

  const initialAmount = 100;
  let insDataMarket;

  const n = '0x0000000000000000000000000000000000000000000000000000000000000001';
  const p = 1;
  const rootKeys = '0x0000000000000000000000000000000000000000000000000000000000000001';
  const rootCryptograms = '0x0000000000000000000000000000000000000000000000000000000000000002';

  before(async () => {
    // Deploy data market
    insDataMarket = await DataMarket.new(n, p, rootKeys, rootCryptograms, { from: seller });
    expect(insDataMarket).to.not.be.equal(undefined);
  });

  it('check balance', async () => {
    await insDataMarket.sellerCancel();

  });

  it('transfer', async () => {

  });

  it('delegate', async () => {

  });
});
