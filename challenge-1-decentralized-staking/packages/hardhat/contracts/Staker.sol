// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping(address => uint256) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 30 seconds;
  bool public openForWithdraw = false;

  event Stake(address addr, uint256 value);
  event Withdraw(address addr, uint256 value);

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
  function stake() public payable{
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }


  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  function execute() public returns (uint256) {
    if(!metThreshold()) {
      openForWithdraw = true;
      return 1;
    }
    if(block.timestamp >= deadline) {
      exampleExternalContract.complete{value: address(this).balance}();
      return 0;
    }
    openForWithdraw = false;
    return 1;
  }

  // Add a `withdraw` function to let users withdraw their balances
  function withdraw() public payable {
    require(timeLeft() == 0, "deadline does not meet");
    require(!metThreshold(), "threshold not met yet");
    uint256 amount = balances[msg.sender];
    require(amount > 0, "you don't have a balance");
    (bool sent,) = msg.sender.call{value: amount}("");
    require(sent, "failed to sent ether");
    balances[msg.sender] = 0;
    emit Withdraw(msg.sender, amount);
  }

  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
  function metThreshold() public view returns (bool) {
    return address(this).balance >= threshold;
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if(block.timestamp >= deadline) return 0;
    return deadline - block.timestamp;
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }
}
