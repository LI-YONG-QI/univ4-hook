// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

contract Counter {
    uint256 public count;

    constructor(uint256 _init) {
        count = _init;
    }

    function increment(uint256 value) public {
        count += value;
    }

    function decrement() public {
        count -= 1;
    }

    function getCount() public view returns (uint256) {
        return count;
    }
}
