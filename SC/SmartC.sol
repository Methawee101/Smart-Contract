// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "./CommitReveal.sol";
import "./TimeUnit.sol";

contract SmartC is CommitReveal, TimeUnit
 {
    uint public numPlayer = 0;
    uint public reward = 0;
    mapping (address => uint) public player_choice; // 0 - Rock, 1 - Paper , 2 - Scissors ,3-Spock , 4 - Lizard
    mapping(address => bool) public player_not_played;
    address[] public players = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    ];

    uint public numInput = 0;
    uint public constant timeOut= 3 minutes;

     modifier onlyPlay() {
        bool allowed = false;
        for (uint i = 0; i < players.length; i++) {
            if (msg.sender == players[i]) allowed = true;
        }
        require(allowed);
        _;
    }
  
    function addPlayer() public payable onlyPlay {
        require(numPlayer < 2);
        if (numPlayer > 0) {
            require(msg.sender != players[0]);
        }
        require(msg.value == 1 ether);
        reward += msg.value;
        player_not_played[msg.sender] = true;
        players.push(msg.sender);
        numPlayer++;
        
        if (numPlayer == 1) {
            setStartTime();
        }  
        
    }

    function Refund()  public{
        require(numPlayer < 2 || (numPlayer == 2 && numInput < 2));
        require(elapsedMinutes() >= timeOut);

        for (uint i = 0; i < players.length; i++) {
        if (player_not_played[players[i]]) {
            payable(players[i]).transfer(reward / numPlayer);
            player_not_played[players[i]] = false;
        }
    }}


function input(uint choice, bytes32 randomString) public onlyPlay {
    require(numPlayer == 2, "Not enough players");
    require(choice >= 0 && choice <= 4, "Invalid choice");
    require(player_not_played[msg.sender], "Player has already chosen");

    // Hash choice และ randomString เพื่อซ่อนตัวเลือก
    bytes32 dataHash = keccak256(abi.encodePacked(choice, randomString));
    commit(dataHash);
    player_not_played[msg.sender] = false;
    numInput++;
}

    function revealChoice(uint choice, bytes32 randomString) public onlyPlay {
    require(numPlayer == 2, "Not enough players");

    // Reveal choice
    bytes32 revealHash = keccak256(abi.encodePacked(choice, randomString));
    reveal(revealHash);

    player_choice[msg.sender] = choice;

    if (player_choice[players[0]] != 0 && player_choice[players[1]] != 0) {
        _checkWinnerAndPay();
    }
}




  
    function _checkWinnerAndPay() private {
    uint p0Choice = player_choice[players[0]];
    uint p1Choice = player_choice[players[1]];
    address payable account0 = payable(players[0]);
    address payable account1 = payable(players[1]);

    if ((p0Choice == 0 && (p1Choice == 2 || p1Choice == 4)) ||
        (p0Choice == 1 && (p1Choice == 0 || p1Choice == 3)) ||
        (p0Choice == 2 && (p1Choice == 1 || p1Choice == 4)) ||
        (p0Choice == 3 && (p1Choice == 0 || p1Choice == 2)) ||
        (p0Choice == 4 && (p1Choice == 1 || p1Choice == 3))) {
        // to pay player[0]
        (bool success0, ) = account0.call{value: reward}("");
        require(success0, "Transfer failed");
    } else if ((p1Choice == 0 && (p0Choice == 2 || p0Choice == 4)) ||
        (p1Choice == 1 && (p0Choice == 0 || p0Choice == 3)) ||
        (p1Choice == 2 && (p0Choice == 1 || p0Choice == 4)) ||
        (p1Choice == 3 && (p0Choice == 0 || p0Choice == 2)) ||
        (p1Choice == 4 && (p0Choice == 1 || p0Choice == 3))) {
        // to pay player[1]
        (bool success1, ) = account1.call{value: reward}("");
        require(success1, "Transfer failed");
    } else {
        // to split reward
        (bool success0, ) = account0.call{value: reward / 2}("");
        require(success0, "Transfer failed");
        (bool success1, ) = account1.call{value: reward / 2}("");
        require(success1, "Transfer failed");
    }

    numInput = 0;
    numPlayer = 0;
    reward = 0;

    player_not_played[players[0]] = true;
    player_not_played[players[1]] = true;
}
}