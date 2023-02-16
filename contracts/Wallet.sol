// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./PriceConsumer.sol";

contract Wallet is Ownable {
  uint public constant usdDecimals = 2;
  uint public constant tokenDecimals = 18;
  uint public constant nftPrice = 100;
  uint256 public  ownerEthAmountToWithdraw;
  uint256 public  ownerTokenAmountToWithdraw;

  address public oraclesEthUsdPrice;
  address public oraclesTokenUsdPrice;

  PriceConsumerV3 public ethUsdContract; 
  PriceConsumerV3 public stableUsdContract; 

  mapping (address => uint256) public userEthDeposit;
  mapping (address => mapping (address => uint256)) public userTokenDeposit;
  constructor(address clEthUsd,address clTokenUsd )  {

    oraclesEthUsdPrice = clEthUsd;
    oraclesTokenUsdPrice = clTokenUsd;
    ethUsdContract = new PriceConsumerV3(oraclesEthUsdPrice);
    stableUsdContract = new PriceConsumerV3(oraclesTokenUsdPrice);
  }


  receive() external payable {
    registeredUserDeposit(msg.sender, msg.value);
  }


  function registeredUserDeposit(address sender, uint256 amount) internal {
    userEthDeposit[sender] += amount;
  }

  function convertETHInUSD(address user) public view returns (uint){
    uint ethPriceDecimals = ethUsdContract.getPriceDecimals();
    uint ethPrice = uint(ethUsdContract.getLatestPrice());
    uint divDecs = 18 + ethPriceDecimals - usdDecimals;
    uint userUSDDeposit = userEthDeposit[user] * ethPrice / (10 ** divDecs); //scaled 10^26 / 10^24 = 10 ^2
    return  userUSDDeposit;
  }

  function convertUSDInETH(uint usdAmount) public view returns (uint){
    uint ethPriceDecimals = stableUsdContract.getPriceDecimals();
    uint ethPrice = uint(stableUsdContract.getLatestPrice());
    uint mulDesc = 18 + ethPriceDecimals - usdDecimals;
    uint convertAmountInEth = usdAmount * (10 ** mulDesc) / ethPrice; //scaled 10^26 / 10^8 = 10 ^18
    return convertAmountInEth;

  }

  function tranfertEthAmountOnBuy(uint nftNumber) public {
    uint calcTotalUSDAmount = nftPrice * nftNumber * (10 ** 2); // In USD
    uint ethAmountForBuying = convertUSDInETH(calcTotalUSDAmount); // In ETH
    require(userEthDeposit[msg.sender] >= ethAmountForBuying, "not enough deposits by the user");
    ownerEthAmountToWithdraw += ethAmountForBuying;
    userEthDeposit[msg.sender] -= ethAmountForBuying;
  }

  function userDeposit(address token, uint amount) external {
    SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);
    userTokenDeposit[msg.sender] [token] += amount;
  }
  

   function convertTokenInUSD(address user) public view returns (uint){
    uint tokenPriceDecimals = stableUsdContract.getPriceDecimals();
    uint tokenPrice = uint(stableUsdContract.getLatestPrice());
    uint divDecs = 18 + tokenPriceDecimals - usdDecimals;
    uint userUSDDeposit = userEthDeposit[user] * tokenPrice / (10 ** divDecs); //scaled 10^26 / 10^24 = 10 ^2
    return  userUSDDeposit;
  }

  function convertUSDInToken(uint usdAmount) public view returns (uint){
    uint tokenPriceDecimals = stableUsdContract.getPriceDecimals();
    uint tokenPrice = uint(stableUsdContract.getLatestPrice());
    uint mulDesc = 18 + tokenPriceDecimals - usdDecimals;
    uint convertAmountInToken = usdAmount * (10 ** mulDesc) / tokenPrice; //scaled 10^26 / 10^8 = 10 ^18
    return convertAmountInToken;

  }

  function tranfertTokenAmountOnBuy(address token, uint nftNumber) public {
    uint calcTotalUSDAmount = nftPrice * nftNumber * (10 ** 2); // In USD
    uint tokenAmountForBuying = convertUSDInToken(calcTotalUSDAmount); // In ETH
    require(userTokenDeposit[msg.sender][token] >= tokenAmountForBuying, "not enough deposits by the user");
    ownerTokenAmountToWithdraw += tokenAmountForBuying;
    userTokenDeposit[msg.sender][token] -= tokenAmountForBuying;
  }


  function getNativeCoinsBalance() external view returns (uint256) {
    return address(this).balance;
  }

  function getTokenBalance(address _token) external view returns (uint256) {
    return IERC20(_token).balanceOf(address(this));
  }

  function nativeCoinsWithdraw() external onlyOwner {
    require(ownerEthAmountToWithdraw > 0 , "no eth to withdraw");
    uint256 tmpAmount = ownerEthAmountToWithdraw;
    ownerEthAmountToWithdraw = 0;
    (bool sent, ) =  payable(msg.sender).call{value:tmpAmount} ("");
    require(sent, "!sent");
  }


  function userETHWithdraw () external {
    require(userEthDeposit[msg.sender] > 0 , "no eth to withdraw");
    (bool sent, ) =  payable(msg.sender).call{value:userEthDeposit[msg.sender]} ("");
    require(sent, "!sent");
    userEthDeposit[msg.sender] = 0;
  }
  function tokenWithdraw (address _token) external onlyOwner {
    require(ownerTokenAmountToWithdraw > 0 , "no eth to withdraw");
    uint256 tmpAmount = ownerTokenAmountToWithdraw;
    ownerTokenAmountToWithdraw = 0;
    SafeERC20.safeTransfer(IERC20(_token), msg.sender, tmpAmount);
  }

  function userTokenWithdraw(address _token) external onlyOwner {
    require(userTokenDeposit[msg.sender][_token] > 0 , "no eth to  withdraw");
    uint256 tmpAmount = userTokenDeposit[msg.sender][_token];
    userTokenDeposit[msg.sender][_token] = 0;
    SafeERC20.safeTransfer(IERC20(_token), msg.sender, tmpAmount);
  }
}
