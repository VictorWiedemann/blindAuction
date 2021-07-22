pragma solidity 0.5.1;




contract generateHash{
    
    uint256 public bid;
    uint256 public nonce;
    uint256 public hash;
    uint nonceSeed;
    
    constructor(uint256 userInputForNonce) public { 
         nonceSeed = userInputForNonce;
    }
    
    uint maxNonce = 2**256 - 1;
    

    function generateTheHash(uint32 _bid) public{
        bid = _bid;
        nonce = uint256(keccak256(abi.encodePacked(now, msg.sender, nonceSeed))) % maxNonce;
        //nonce = 10;
        
        hash = uint256(keccak256(abi.encodePacked(bid, nonce)));
    }
    
    
}


contract SimpleAuction {

    //this is the wallet that sets up the auction
    address admin; 
    
    ///Until this time, bids can keep coming in.
    uint bidEndTime;
    
    ///from bidEndTime till revealEndTime, people can reveal their bids
    uint revealEndTime;

    //the minimum required bid for the auction.
    uint256 public minimumBidWei;
    uint256 public minimumBidEther;
    
    address payable myWallet;
    
    uint public valueOfHighestBid;
    address public highestBidder;    
    
    /// Create a simple auction with _biddingTime seconds bidding time on behalf of the my wallet address _mywallet
    constructor(address payable _myWallet, uint256 _minimumBid) public {
        myWallet = _myWallet;
        minimumBidEther = _minimumBid;
        minimumBidWei = minimumBidEther * (10**18);
        admin = msg.sender;
        bidEndTime = now + 120;
        revealEndTime = bidEndTime + 180;
        valueOfHighestBid = 0;
    }
    
    
    // 1 wei == 1 wei
    // 1 szabo == 1e12 wei
    // 1 finney == 1e15 wei
    // 1 ether == 1e18 wei

    struct biddersInfo{
        uint256 bid;
        uint256 weiInAccount;
        uint256 nonce; 
        uint256 givenHash;
        uint256 CalculatedHash;
        bool isHashAccurate;
    }
    mapping (address => biddersInfo) public biddersList;


    ///save the bidders hash and their maximum ether in their account.
    function submitBid(uint256 _hash) public payable biddingTime{
        //ensure that the amount of money is larger than the minimumBid.
       biddersList[msg.sender].givenHash = _hash;
       biddersList[msg.sender].weiInAccount = msg.value;
       require(biddersList[msg.sender].weiInAccount > minimumBidWei);

    }
    

    function confirmBid(uint256 _bid, uint256 _nonce ) public revealTime{


        biddersList[msg.sender].nonce = _nonce;
        biddersList[msg.sender].CalculatedHash = uint256(keccak256(abi.encode(_bid, _nonce)));
        
        //do the hashes match?
        biddersList[msg.sender].isHashAccurate = (biddersList[msg.sender].givenHash == biddersList[msg.sender].CalculatedHash);
        biddersList[msg.sender].bid = (_bid * 1E18);
        
        //ensure that the bid is higher than the mandatory minimum bid, and lower than the entire amount of wei in account
        require(_bid > minimumBidEther);
        require(biddersList[msg.sender].bid  < biddersList[msg.sender].weiInAccount);
        
        //do error checking on this transaction to see if this bid is accurate.
        require(biddersList[msg.sender].isHashAccurate);
        
        //If this bid is larger than the first bid, replace it as the top bid.
        if (biddersList[msg.sender].bid > valueOfHighestBid) {
            valueOfHighestBid = biddersList[msg.sender].bid;
            highestBidder = msg.sender;
        }
    }
    






    //to track the current state, this is being used for demo purposes
    auctionState public state;
    function aaBidPhase() public onlyAdmin{
        state = auctionState.bidding;
    }
    function aRevealPhase() public onlyAdmin{
        state = auctionState.reveal;
    }
    
    //The auction house closes the auction and withdraws the winners Ether
    function zEndAuction() public onlyAdmin{
        state = auctionState.showWinner;
        
        //Now take the money from the new highest bidder
        biddersList[highestBidder].weiInAccount -= valueOfHighestBid;
        msg.sender.transfer(valueOfHighestBid);
        valueOfHighestBid = 0;

    }
    
    function withdrawBiddersFunds() public afterWinnerSelected{
        msg.sender.transfer(biddersList[msg.sender].weiInAccount);
        biddersList[msg.sender].weiInAccount = 0;
    }

    
    
    
    
    
    
    
    
    //below here is for shared require statements.
    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }
    
    enum auctionState {bidding, reveal, showWinner}
    modifier revealTime(){
        //uint revealEndTime = bidEndTime + 60;
        //require(block.timestamp > bidEndTime);
        //require(block.timestamp < revealEndTime);
        require (state == auctionState.reveal);
        _;
    }
    
    //will only allow bids during the specified length of time
    modifier biddingTime(){
        //require(block.timestamp < bidEndTime);
        require (state == auctionState.bidding);
        _;
    }
    
    modifier afterWinnerSelected(){
        require (state == auctionState.showWinner);
        _;
    }
}
