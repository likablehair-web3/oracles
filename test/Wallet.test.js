const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');
const { expect } = require('chai');
const { ZERO_ADDRESS, MAX_UINT256 } = constants;


const Wallet = artifacts.require("Wallet")
const Token = artifacts.require("Token")
const fromWei = (x) => web3.utils.fromWei(x.toString());
const toWei = (x) => web3.utils.toWei(x.toString());

contract('Wallet', function (accounts) {

  const [deployer, firstAccount, secondAccount, fakeOwner] = accounts;

  it('retrieve deployed contract', async function () {
    walletContract = await Wallet.deployed();
    expect(walletContract.address).to.be.not.equal(ZERO_ADDRESS)
    expect(walletContract.address).to.match(/0x[0-9a-fA-F]{40}/);

    tokenContract = await Token.deployed();
    expect(tokenContract.address).to.be.not.equal(ZERO_ADDRESS)
    expect(tokenContract.address).to.match(/0x[0-9a-fA-F]{40}/);
  
  });

  
  it('distributed some tokens fromm deployer', async function () {
    await tokenContract.transfer(firstAccount, toWei(100000))
    await tokenContract.transfer(secondAccount, toWei(150000))

    balanceDeploy = await tokenContract.balanceOf(deployer)
    balanceFirstAccount = await tokenContract.balanceOf(firstAccount)
    balanceSecondAccount = await tokenContract.balanceOf(secondAccount)

    console.log(fromWei(balanceDeploy),fromWei(balanceFirstAccount), fromWei(balanceSecondAccount))
  });

  it('who is the contract owner', async function () {
    ownerAddress = await walletContract.owner()
    expect(ownerAddress).to.be.equal(deployer)
  });

  it('firstAccount and secondAccount sends some ethers to wallet contract', async function () {

    
    await web3.eth.sendTransaction({
      from:firstAccount,
      to: walletContract.address,
      value: toWei(1)
    })

    await web3.eth.sendTransaction({
      from:secondAccount,
      to: walletContract.address,
      value: toWei(1.5)
    })


    balance = await walletContract.getNativeCoinsBalance()
    console.log(fromWei(balance))
    
  });

  
  
  it('owner withdraws wallet eth amount', async function()  {
    await expectRevert.unspecified(walletContract.nativeCoinsWithdraw(toWei(3)))
    await expectRevert(walletContract.nativeCoinsWithdraw(toWei(2), {from:fakeOwner}), "Ownable: caller is not the owner")

    await walletContract.nativeCoinsWithdraw(toWei(2), {from:deployer})
    balance = await walletContract.getNativeCoinsBalance()
    console.log(fromWei(balance))
  });

  it('firstAccount and secondAccount sends some ethers to wallet contract', async function () {
    await tokenContract.transfer(walletContract.address, toWei(80000), {from:firstAccount})
    await tokenContract.transfer(walletContract.address, toWei(120000), {from:secondAccount})

    balance = await walletContract.getTokenBalance(tokenContract.address)
    console.log(fromWei(balance))
    
  });

  
  it('owner withdraws wallet token amount', async function()  {
    await expectRevert.unspecified(walletContract.tokenWithdraw(tokenContract.address,toWei(300000)))
    await expectRevert(walletContract.tokenWithdraw(tokenContract.address, toWei(175000), {from:fakeOwner}), "Ownable: caller is not the owner")

    await walletContract.tokenWithdraw(tokenContract.address, toWei(175000), {from:deployer});
    balance = await walletContract.getTokenBalance(tokenContract.address)
    console.log(fromWei(balance))
  });
});
