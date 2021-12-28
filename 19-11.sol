// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Fabrication {

    uint256 public units;
    address payable owner;
    address[] admins;
    uint256 public timeOfLastFabricationOrder;

    constructor(uint256 initialUnits) {
        owner = payable(msg.sender);
        units = initialUnits;
        timeOfLastFabricationOrder = block.timestamp;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isAdmin() {
        bool isAdmn;
        for (uint32 i; i < admins.length; i++) {
            if (msg.sender == admins[i]){
                isAdmn == true;
                break;
            }
        }
        require(isAdmn == true);
        _;
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function addAdmin(address newAdmin) isOwner public {
        admins.push(newAdmin);
    }

    function setUnits(uint256 num) isAdmin isOwner external {
        require(block.timestamp > timeOfLastFabricationOrder + 3 days);
        units = num;
        timeOfLastFabricationOrder = block.timestamp;
    }

    function increaseUnits(uint256 increase) payable public {
        // 0.01 ether per unit
        // 1 wei = 10^-18
        require(msg.value >= increase * 0.01 ether, "Not enough ether");
        units = units + increase;
    }

    function withdraw() public {
        owner.transfer(balance());
    }

    receive() external payable {
    }
}
