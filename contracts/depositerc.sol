// SPDX-License-Identifier: GPL-3.0

    pragma solidity ^0.8.0;

    import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

    contract StoreISHTokens{
        
        ERC20 private ERC20interface;
        
        address public tokenAdress; // This is the token address
        address payable public owner; // This is the client
        // uint public expenses; // The fee in eth to be stored in the smart contract (for example)


        
        constructor (){
            tokenAdress = 0xF791ff20C453b718a85721C0E543a788E73D1eEc; 
            ERC20interface = ERC20(tokenAdress);
            owner = payable(msg.sender);
            }
        
        event Transfer(address indexed _from, address indexed _to, uint256 _value);
        event Approval(address indexed _owner, address indexed _spender, uint256 _value);

        
        function contractBalance() public view returns (uint _amount){
            return ERC20interface.balanceOf(address(this));
        }
          function addressss() public view returns (address){
            return address(this);
        }
        
        
        function senderBalance() public view returns (uint){
            return ERC20interface.balanceOf(msg.sender);
        }
        
        function approveSpendToken(uint _amount) public returns(bool){
            return ERC20interface.approve(address(this), _amount); // We give permission to this contract to spend the sender tokens
            //emit Approval(msg.sender, address(this), _amount);
        }
        
        function allowance() public view returns (uint){
            return ERC20interface.allowance(msg.sender, address(this));
        }
        
        
        function depositISHTokens (uint256 _amount) external payable {
            address from = msg.sender;
            address to = address(this);

            ERC20interface.transferFrom(from, to, _amount);
        }
        

            function transferBack (address payable _to) public payable  {
            _to = payable(msg.sender);
            uint balance = ERC20interface.balanceOf(address(this)); // the balance of this smart contract
            ERC20interface.transferFrom(address(this), _to, balance);
        }
        
     
    }
