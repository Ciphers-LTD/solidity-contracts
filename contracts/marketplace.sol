// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;


import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Pausable.sol";
import "./IERC721Verifiable.sol";
import "./FeeManager.sol";
import "./ERC20Token.sol";
import "./NFTToken.sol";


contract NFTMarketplace is Pausable, FeeManager, ERC721Holder {
    
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    IERC20 public acceptedToken;
    
    constructor(address _acceptedToken)  Ownable() {
        require(_acceptedToken.isContract(), "The accepted token address must be a deployed contract");
        acceptedToken = IERC20(_acceptedToken);
    }
    
    function setPaused(bool _setPaused) public onlyOwner {
        return (_setPaused) ? pause() : unpause();
    }
    
    struct Order {
        
        // OrderId
        bytes32 orderId;
        // Seller Address
        address payable seller;
        // Selling Price
        uint256 askingPrice;
        //Time when sale ends
        uint256 expiryTime;
        // is item sold
        address tokenAddress;
    
    }
    
    struct Bid {
        
        bytes32 bidId;
        address bidder;
        uint256 bidPrice;
        // Time when this bid ends
        uint256 expiryTime;
    }
    
     // ORDER EVENTS
     
    event OrderCreated(
        bytes32 orderId,
        address indexed seller,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 askingPrice,
        uint256 expiryTime
    );

    event OrderUpdated(
        bytes32 orderId,
        uint256 askingPrice,
        uint256 expiryTime
    );

    event OrderSuccessful(
        bytes32 orderId,
        address indexed buyer,
        uint256 expiryTime
    );

    event OrderCancelled(bytes32 id);

    // BID EVENTS
    event BidCreated(
      bytes32 id,
      address indexed tokenAddress,
      uint256 indexed tokenId,
      address indexed bidder,
      uint256 priceInWei,
      uint256 expiryTime
    );

    event BidAccepted(bytes32 id);
    event BidCancelled(bytes32 id);
    
    //mapping
    mapping(address => mapping(uint256 => Order)) public orderByTokenId;  

    mapping(address => mapping(uint256 => Bid)) public bidByOrderId;   
    
    bytes4 public constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    
    /*public functions*/
    
    
    //create order
    function createOrder(address _tokenAddress, uint256 _tokenId, uint256 _askingPrice, uint256 _expiryTime) public whenNotPaused {
        
        _createOrder( _tokenAddress,  _tokenId,  _askingPrice,  _expiryTime);
    }
    
    
    //cancel order
    function cancelOrder(address _tokenAddress, uint256 _tokenId) public whenNotPaused {
        
        Order memory order = orderByTokenId[_tokenAddress][_tokenId];
        
        require(order.seller == msg.sender || msg.sender == owner(), "Marketplace: unauthorized sender");
        
         Bid memory bid = bidByOrderId[_tokenAddress][_tokenId];
         
         if(bid.bidId != 0 ) {
             _cancelBid(bid.bidId, _tokenAddress,  _tokenId,  bid.bidder,  bid.bidPrice);
         }
         
         _cancelOrder(order.orderId,  _tokenAddress,  _tokenId,  msg.sender);
    
    }
    
    
    function updateOrder(address _tokenAddress, uint256 _tokenId, uint256 _askingPrice, uint256 _expiryTime) public whenNotPaused {
        
        Order memory order = orderByTokenId[_tokenAddress][_tokenId];
        require(order.orderId != 0, "Markeplace: Order not yet published");
        require(order.seller == msg.sender, "Markeplace: sender is not allowed");
        require(order.expiryTime >= block.timestamp, "Markeplace: Order expired");
        require(order.askingPrice > 0, "Marketplace: Price should be bigger than 0");
        
        require(_expiryTime > block.timestamp.add(1 minutes), "Marketplace: Expire time should be more than 1 minute in the future"
        );

        order.askingPrice = _askingPrice;
        order.expiryTime = _expiryTime;

        emit OrderUpdated(order.orderId, _askingPrice, _expiryTime);
    }
    
    //execute order to the buyer
    function safeExecuteOrder(address _tokenAddress, uint256 _tokenId, uint256 _askingPrice) public whenNotPaused {
        
        
        Order memory order = _getValidOrder(_tokenAddress, _tokenId);
        
        require(order.askingPrice == _askingPrice, "Marketplace: invalid price");
        require(order.seller != msg.sender, "Marketplace: unauthorized sender");
        
        // Check the NFT token fingerprint
        
        
        uint256 saleShareAmount = 0;
        
        if (FeeManager.cutPerMillion > 0) {
            
            // Calculate sale share
            saleShareAmount = _askingPrice.mul(FeeManager.cutPerMillion).div(1e6);

            // Transfer share amount for marketplace Owner
            acceptedToken.safeTransferFrom(msg.sender,owner(),saleShareAmount);
        }
        
         // Transfer accepted token amount minus market fee to seller
        acceptedToken.safeTransferFrom(msg.sender, order.seller, order.askingPrice.sub(saleShareAmount));
        
         // Remove pending bid if any
        Bid memory bid = bidByOrderId[_tokenAddress][_tokenId];
        
        if(bid.bidId !=0 ) {
            _cancelBid(bid.bidId, _tokenAddress, _tokenId, bid.bidder, bid.bidPrice);
        }
        
        _executeOrder(order.orderId, msg.sender,  _tokenAddress,  _tokenId,  _askingPrice);

        
    }
    
    function safePlaceBid(address _tokenAddress, uint256 _tokenId, uint256 _askingPrice, uint256 _expiryTime) public whenNotPaused {
        
        // Check the NFT token fingerprint
     
        _createBid( _tokenAddress,  _tokenId,  _askingPrice,  _expiryTime);
    
    }
    
    function cancelBid(address _tokenAddress, uint256 _tokenId) public whenNotPaused {
        
        Bid memory bid = bidByOrderId[_tokenAddress][_tokenId];
        require(bid.bidder == msg.sender || msg.sender == owner(), "Marketplace: Unauthorized sender");
        
        _cancelBid(bid.bidId, _tokenAddress, _tokenId, bid.bidder, bid.bidPrice);
    }
    
    
    /* */
    function acceptBidandExecuteOrder(address _tokenAddress, uint256 _tokenId, uint256 _bidPrice) public whenNotPaused {
        
        Order memory order = orderByTokenId[_tokenAddress][_tokenId];
        require(order.seller == msg.sender, "Marketplace, Unauthorized sender");
        
        Bid memory bid = bidByOrderId[_tokenAddress][_tokenId];
        require(bid.bidPrice == _bidPrice, "Markeplace: invalid bid price");
        require(bid.expiryTime >= block.timestamp, "Markeplace: the bid expired");
        
        delete bidByOrderId[_tokenAddress][_tokenId];
        
        emit BidAccepted(bid.bidId);
        
         // calc market fees
        uint256 saleShareAmount = bid.bidPrice.mul(FeeManager.cutPerMillion).div(1e6);
        
        // transfer escrowed bid amount minus market fee to seller
         acceptedToken.safeTransfer(bid.bidder, bid.bidPrice.sub(saleShareAmount));

        _executeOrder(order.orderId, msg.sender,  _tokenAddress,  _tokenId,  _bidPrice);    
        
    }
    
    
    

    //internal functions
    function _createOrder(address _tokenAddress, uint256 _tokenId, uint256 _askingPrice, uint256 _expiryTime) internal   {
        
        // Check nft registry
         IERC721 tokenRegistry = IERC721(_tokenAddress);
         
        // Check order creator is the asset owner
        address tokenOwner = tokenRegistry.ownerOf(_tokenId);
        
        require(tokenOwner == msg.sender,"Marketplace: Only the asset owner can create orders");
        require(_askingPrice > 0, "not enough funds send");
        require(_expiryTime > block.timestamp.add(5000),"Marketplace: Publication should be more than 1 minute in the future");
        
        tokenRegistry.safeTransferFrom(tokenOwner,address(this), _tokenId);
        
        
        
        // create the orderId
        bytes32 _orderId = keccak256(abi.encodePacked(block.timestamp,_tokenAddress,_tokenId, _askingPrice));
        
        orderByTokenId[_tokenAddress][_tokenId] = Order({
            orderId: _orderId,
            seller: payable(msg.sender),
            tokenAddress: _tokenAddress,
            askingPrice: _askingPrice,
            expiryTime: _expiryTime
        });
        
        emit OrderCreated(_orderId,msg.sender,_tokenAddress,_tokenId,_askingPrice,_expiryTime);

    }
    
    

    function _createBid(address _tokenAddress, uint256 _tokenId, uint256 _askingPrice, uint256 _expiryTime) internal   {
        
        // Checks order validity
        Order memory order = _getValidOrder(_tokenAddress, _tokenId);
        
        if(_expiryTime > order.expiryTime) {
            _expiryTime = order.expiryTime;
        }
        
        Bid memory bid = bidByOrderId[_tokenAddress][_tokenId];
        
        if(bid.bidId != 0) { 
            
            if(bid.expiryTime >= block.timestamp) {
                require(_askingPrice > bid.bidPrice, "Marketplace: bid price should be higher than last bid");
            } else {
                require(_askingPrice > 0, "Marketplace: bid should be > 0");
            }
            
            _cancelBid(bid.bidId,_tokenAddress,_tokenId,bid.bidder,bid.bidPrice);
            
        } else 
        {
            require(_askingPrice > 0, "Marketplace: bid should be > 0");
        }
        
        //msg.sender is bidder
        acceptedToken.safeTransferFrom(msg.sender, address(this), _askingPrice);
        
        bytes32 bidId = keccak256(abi.encodePacked(block.timestamp, msg.sender, order.orderId, _askingPrice, _expiryTime));
        
        bidByOrderId[_tokenAddress][_tokenId] = Bid({
            bidId: bidId,
            bidder: msg.sender,
            bidPrice: _askingPrice,
            expiryTime: _expiryTime
        });
        
         emit BidCreated(bidId,_tokenAddress,_tokenId,msg.sender,_askingPrice,_expiryTime);
         
}


        function _executeOrder(bytes32 _orderId, address _buyer, address _tokenAddress, uint256 _tokenId, uint256 _askingPrice) internal {
            
            delete orderByTokenId[_tokenAddress][_tokenId];
            
            IERC721(_tokenAddress).safeTransferFrom(address(this), _buyer, _tokenId);
            
            emit OrderSuccessful(_orderId, _buyer, _askingPrice);
        }
        
        
        
        function _getValidOrder(address _tokenAddress, uint256 _tokenId) internal view returns (Order memory order) {
            order = orderByTokenId[_tokenAddress][_tokenId];
            
            require(order.orderId != 0, "Marketplace: asset not published");
            require(order.expiryTime >= block.timestamp, "Marketplace: order expired");
        }
    
    
        function _cancelBid(bytes32 _bidId, address _tokenAddress, uint256 _tokenId, address _bidder, uint256 _escrowAmount) internal {
            delete bidByOrderId[_tokenAddress][_tokenId];
    
            // return escrow to canceled bidder
            acceptedToken.safeTransfer(_bidder, _escrowAmount);
    
            emit BidCancelled(_bidId);
        }
    
    
        function _cancelOrder(bytes32 _orderId, address _tokenAddress, uint256 _tokenId, address _seller) internal {
            
            delete orderByTokenId[_tokenAddress][_tokenId];
            IERC721(_tokenAddress).safeTransferFrom(address(this), _seller, _tokenId);
            
            emit OrderCancelled(_orderId);
        }
    
    
    
       function _requireERC721(address _tokenAddress) internal view returns (IERC721) {
            require(
                _tokenAddress.isContract(),
                "The NFT Address should be a contract"
            );
            require(
                IERC721(_tokenAddress).supportsInterface(_INTERFACE_ID_ERC721),
                "The NFT contract has an invalid ERC721 implementation"
            );
            return IERC721(_tokenAddress);
        }
    
    
      
        
        
}
