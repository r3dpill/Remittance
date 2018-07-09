pragma solidity ^0.4.24;

import './Owned.sol';

contract Stoppable is Owned {

    bool public isRunning;
    
    modifier onlyIfRunning() {
        require(isRunning == true);
        _;
}
    constructor() public {
        isRunning = true;
    }
    
    function setState(bool isOn)
        public
        onlyOwner
        returns(bool success)
    {
        isRunning = isOn;
    }
}
