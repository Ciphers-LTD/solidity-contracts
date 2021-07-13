pragma solidity ^0.8.1;

contract Voting{
    
    uint public counter;
    
    struct VotingData{
        address candidateAddress;
        
        address voter;
        uint votes;
        
        
    }
    
    mapping(address => VotingData) public myVoting;
     
     mapping(address=>bool) public _voterExist;
     
     mapping(address=>bool) public _candidateAddressExist;
     
    //  function vote() public returns (uint){
         
    //      counter=counter+1;
         
    //      return counter;
    
        
    //  }
     
    function voting(address _candidateAddress)public
    {
        require(!_voterExist[msg.sender]);
        
        if(_candidateAddressExist[_candidateAddress]!=true)
        {
            counter=1;
        }
        else
        {
            counter=counter+1;
        }
            
         myVoting[_candidateAddress] = VotingData({
            candidateAddress : _candidateAddress,
           
            voter:msg.sender,
            votes:counter
            
            
           });
           _voterExist[msg.sender]=true;
           _candidateAddressExist[_candidateAddress]=true;
        
      
}
 function get(address _candidateAddress) public  view 
        returns (address ,  address ,uint )
    {
        VotingData storage votingdata = myVoting[_candidateAddress];
        return (votingdata.candidateAddress,votingdata.voter,votingdata.votes);
    }
}
