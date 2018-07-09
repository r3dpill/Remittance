pragma solidity ^0.4.24;

import './Stoppable.sol';
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract Remittance is usingOraclize, Stoppable {
    
    bool contractLive = false;
    address owner;
    address payTo;
    uint deadline;          // block number after which Alice may reclaim funds
    uint contractValue;
    bytes32 hashRecipient;
    bytes32 hashValidator;
    uint public startRate;
    uint public endRate;
    uint toSend;
    
    event LogPayment(string pmtType, uint pmtAmount);
    
    // required by oraclize 
    string public EURGBP;
    event LogPriceUpdated(string price);
    event LogNewOraclizeQuery(string description);
    
    constructor() public payable {
        owner = msg.sender;
    }
    
    function __callback(bytes32 myid, string result) {
        require(msg.sender == oraclize_cbAddress());
        EURGBP = result;
        emit LogPriceUpdated(result);
    }

    function updatePrice() payable {
        if (oraclize_getPrice("URL") > this.balance) {
            emit LogNewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit LogNewOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            oraclize_query("URL", "json(http://api.fixer.io/latest?symbols=USD,GBP).rates.GBP");
        }
    }
    
    function setPayment(bytes32 pwdRecipient, bytes32 pwdValidator, address recipient, uint blockDuration)
        public
        payable
        onlyIfRunning
    {
        require(!contractLive);
        require(msg.value > 0);
        deadline = block.number + blockDuration;
        contractValue += msg.value;
        hashRecipient = keccak256(pwdRecipient);
        hashValidator = keccak256(pwdValidator);
        payTo = recipient;
        updatePrice();
        startRate = parseInt(EURGBP,6);
        contractLive = true;
    }
    
    function requestPayout(bytes32 pwdRecipient, bytes32 pwdValidator)
        public
        onlyIfRunning
    {
        require(contractLive);
        require(checkInfo(pwdRecipient, pwdValidator, msg.sender));
        updatePrice();
        endRate = parseInt(EURGBP,6);
        if (endRate<startRate) {
            toSend = contractValue /startRate * endRate;
        } else {
            toSend = contractValue;
        }
        contractValue = contractValue - toSend;
        msg.sender.transfer(toSend);
        emit LogPayment("Payout", toSend);
        contractLive = false;
    }
    
    function checkInfo(bytes32 pwdRecipient, bytes32 pwdValidator, address requestor) internal view returns (bool) {
        require(requestor == payTo);
        require(keccak256(pwdRecipient) == hashRecipient);
        require(keccak256(pwdValidator) == hashValidator);
        return true;
    }
    
    
    function requestRefund()
        public
        onlyOwner
    {
        require(block.number >= deadline);
        toSend = contractValue;
        contractValue = 0;
        msg.sender.transfer(toSend);
        emit LogPayment("Refund", toSend);
        contractLive = false;
    }
    
    function getContractValue() public view returns(uint) {
        return contractValue;
    }
    
    function isContractLive() public view returns(bool) {
        return contractLive;
    }
    
    function getBlockNumber() public view returns(uint) {
        return block.number;
    }
}
