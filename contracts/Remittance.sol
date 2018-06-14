pragma solidity ^0.4.24;

contract Remittance {
    
    bool killed = false;
    bool contractLive = false;
    address owner;
    address payTo;
    uint deadline;          // block number after which Alice may reclaim funds
    uint contractValue;
    bytes32 hashBob;
    bytes32 hashCarol;
    
    
    constructor() public payable {
        owner = msg.sender;
    }
    
    function setPayment(bytes32 pwdBob, bytes32 pwdCarol, address recipient, uint blockDuration) public payable {
        require(!killed);
        require(!contractLive);
        require(msg.value > 0);
        deadline = block.number + blockDuration;
        contractValue += msg.value;
        hashBob = keccak256(pwdBob);
        hashCarol = keccak256(pwdCarol);
        payTo = recipient;
        contractLive = true;
    }
    
    function requestPayout(bytes32 pwdBob, bytes32 pwdCarol) {
        require(!killed);
        require(contractLive);
        require(checkInfo(pwdBob, pwdCarol, msg.sender));
        uint toSend = contractValue;
        contractValue = 0;
        msg.sender.transfer(toSend);
        contractLive = false;
    }
    
    function checkInfo(bytes32 pwdBob, bytes32 pwdCarol, address requestor) internal view returns (bool) {
        require(requestor == payTo);
        require(keccak256(pwdBob) == hashBob);
        require(keccak256(pwdCarol) == hashCarol);
        return true;
    }
    
    
    function requestRefund() public {
        require(msg.sender == owner);
        require(block.number >= deadline);
        uint toSend = contractValue;
        contractValue = 0;
        msg.sender.transfer(toSend);
        contractLive = false;
    }
    
    function getContractValue() public view returns(uint) {
        return contractValue;
    }
    
    function isContractLive() public view returns(bool) {
        return contractLive;
    }
    
    function setKilledState(bool _killed) public {
        require(msg.sender == owner);
        killed = _killed;
    }
}
