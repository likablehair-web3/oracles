const Wallet = artifacts.require("Wallet")
const Token = artifacts.require("Token")

module.exports  = async (deployer, network, accounts)=>{
  await deployer.deploy(Wallet)
  const wallet = await Wallet.deployed();
  console.log("Deployed wallet is @:" + wallet.address)

  await deployer.deploy(Token, "TestTolìken", "TT1", 1000000); 
  const token = await Wallet.deployed();
  console.log("Deployed Token address(0) :",token.address)
}


