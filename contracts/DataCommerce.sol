/**
 * Description: Implements a data commerce with representative sample checking protocol
 */
pragma solidity ^0.4.24;

import "./safemath.sol";

contract DataMarket {

    using SafeMath for uint256;
    using SafeMath for uint256;

    address public seller; //owner
    address public buyer;
    enum State { Created, Paid, SaltReleased, Challenged, SellerPaid, BuyerRefunded, Cancelled }
    State public state;

    bytes32 public MRC; //commitment del criptograma
    bytes32 public MRK; //commitment de les claus

    uint256 public n; //n� registres de la BBDD
    uint256 public price; //preu
    uint256 public index; //index de la key pel challenge

    uint256 public salt;
    
    uint256 public tpaid;
    uint256 public tsalt;
    uint256 public tchallenge;
    uint256 public timeout = 10;
    
    event StateInfo(State state);
    
    /**
     * @dev 
     */
    modifier onlySeller() {
        require (msg.sender == seller);
        _;
    }

    /**
     * @dev 
     */
    modifier onlyBuyer() {
        require (msg.sender == buyer);
        _;
    }

    /**
     * @dev State requirement
     */
    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    /**
     * @dev Secures that execution is done after a time selected
     */
    modifier onlyAfter(uint _time) { 
        require(now > _time); // now equival a block.timestamp
        _; 
    }


    

    /**
     * @dev Description, N, Ncheck and price saved in the smart contract during the construction
     *
     * @param _hashdescription: Hash of the description provided by the seller (deployer)
     * @param _n: Number of total data samples 
     * @param _ncheck: Number of samples to be revealed
     * @param _price: Price of the whole data
     * 
     */
    constructor (uint256 _n, uint256 _p, uint256 _MRC, uint256 _MRK) payable { //2
        seller = msg.sender;
        n = _n;
        price = _p;
        MRC = _MRC;
        MRK = _MRK;
        //creation_block = block.number;
    }
    
    /**
     * @dev The buyer makes the payment
     * 
     */
    function payB() public payable inState(State.Created) onlyBuyer() {
        if (msg.value >= price) {
            buyer = msg.sender;
            tpaid = now;
            state = State.Paid;
            emit StateInfo(state);
        } else {
            //Torna el pago si no es suficient
            msg.sender.transfer(msg.value);
        }
    }

    /**
     * @dev Seller reveals the salt to decrypt all the data in order to the buyer obtains it. 
     * @param _salt: Salt revealed
     * 
     */
    function saltRelease(uint32 _salt) public payable inState(State.Paid) onlySeller() {
        salt = _salt;
        tsalt = now;
        state = State.SaltReleased;
        emit StateInfo(state);
    }


    /**
     * @dev Seller aborts the protocol
     *
     */
    function sellerCancel() public onlySeller{
        require(state == State.Created);
        state = State.Cancelled;
        emit StateInfo(state);
    }

    /**
     * @dev 
     *
     */
    function sellerPay() public onlySeller{
        require( (state == State.SaltReleased)  && (now > tsalt + timeout) );
        state = State.SellerPaid;
        emit StateInfo(state);
        selfdestruct(seller);
    }

    /**
     * @dev Buyer aborts the protocol
     *
     */
    function buyerRefund() public onlyBuyer {
        require( ( (state == State.Paid) && (now > tpaid + timeout) ) || ( (state == State.Challenged) && (now > tchallenge + timeout) ) );
        state = State.BuyerRefunded;
        emit StateInfo(state);
    }


    /**
     * @dev 
     * @param 
     * 
     */
    function challenge(uint32 _i) public inState(State.SaltReleased) onlyBuyer() {
        index = _i;
        tchallenge = now;
        state = State.Challenged;
        emit StateInfo(state);
    }

    /**
     * @dev 
     * @param 
     * 
     */
    function solveChallenge(uint256[] _MPi) public inState(State.Challenged) onlySeller() {
        uint256 ki = uint256(keccak256(bytes32(salt.add(index))));
        uint256 c;
        for(c; c < _MPi.length; c.add(1)){
            ki = keccak256(ki.add(_MPi[c]));
        }
        
        if (ki == MRK){
            state = State.SellerPaid;
            emit StateInfo(state);
            selfdestruct(seller);
        }else{
            state = State.BuyerRefunded;
            emit StateInfo(state);
            selfdestruct(buyer);
        }
        
    }


}