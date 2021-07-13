
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract UserInfo {
   
        uint counter;
        struct UserData{
            
            string  name;
            string  description;
            string  email;
            string imagePath;
            address  userAddress;
        }
        
        
        

    //User_Data [] public user_info;
    
     mapping(address => UserData) public myuser;
     
     mapping(address=>bool) public _addressExist;
    
    event OrderUpdated(string username,string description,string email,string imagePath);
    function add(string memory _name,string memory _description,string memory _email,string memory _imagePath, address  _userAddress) public
    {
        require(!_addressExist[_userAddress]);
        
        
           myuser[_userAddress] = UserData({
            name : _name,
            description : _description,
            email:_email,
            userAddress:_userAddress,
            imagePath:_imagePath
           });
        
        _addressExist[_userAddress]=true;
       
        
    }
    
     function get(address _user) public  view 
        returns (string memory _name, string memory _description, string memory _email,string memory _imagePath, address userAddress)
    {
        UserData storage userdata = myuser[_user];
        return (userdata.name,userdata.description,userdata.email,userdata.imagePath,userdata.userAddress);
    }
    
    function updateUser(address _useraddress, string memory _username, string memory _description,string memory _email,string memory _imagePath) public
    {
        UserData storage data = myuser[_useraddress];
        
        data.name=_username;
        data.description=_description;
        data.email=_email;
        data.imagePath=_imagePath;
        emit OrderUpdated(data.name,data.description,data.email,data.imagePath);
    }
    

}

