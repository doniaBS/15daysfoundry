// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Wallet {
    event Submit(uint indexed txId, address indexed to, uint value, bytes data);
    event Confirm(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required; // confirmations needed

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint confirmations;
    }

    Transaction[] public transactions;
    // owner => txId => confirmed?
    mapping(address => mapping(uint => bool)) public confirmed;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint txId) {
        require(txId < transactions.length, "tx !exists");
        _;
    }

    modifier notExecuted(uint txId) {
        require(!transactions[txId].executed, "already executed");
        _;
    }

    modifier notConfirmed(uint txId) {
        require(!confirmed[msg.sender][txId], "already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "owners required");
        require(_required > 0 && _required <= _owners.length, "bad required");

        for (uint i; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "zero owner");
            require(!isOwner[owner], "owner not unique");
            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }

    receive() external payable {}

    function submit(address to, uint value, bytes calldata data) external onlyOwner returns (uint txId) {
        transactions.push(Transaction({to: to, value: value, data: data, executed: false, confirmations: 0}));
        txId = transactions.length - 1;
        emit Submit(txId, to, value, data);
    }

    function confirm(uint txId)
        external
        onlyOwner
        txExists(txId)
        notExecuted(txId)
        notConfirmed(txId)
    {
        confirmed[msg.sender][txId] = true;
        transactions[txId].confirmations += 1;
        emit Confirm(msg.sender, txId);
        if (transactions[txId].confirmations >= required) {
            _execute(txId);
        }
    }

    function revoke(uint txId)
        external
        onlyOwner
        txExists(txId)
        notExecuted(txId)
    {
        require(confirmed[msg.sender][txId], "not confirmed");
        confirmed[msg.sender][txId] = false;
        transactions[txId].confirmations -= 1;
        emit Revoke(msg.sender, txId);
    }

    function execute(uint txId) external onlyOwner txExists(txId) notExecuted(txId) {
        require(transactions[txId].confirmations >= required, "not enough confs");
        _execute(txId);
    }

    function _execute(uint txId) internal {
        Transaction storage t = transactions[txId];
        t.executed = true;
        (bool ok, ) = t.to.call{value: t.value}(t.data);
        require(ok, "tx failed");
        emit Execute(txId);
    }

    // Helpers
    function getOwners() external view returns (address[] memory) { return owners; }
    function txCount() external view returns (uint) { return transactions.length; }
    function getTx(uint txId) external view returns (Transaction memory) { return transactions[txId]; }
}