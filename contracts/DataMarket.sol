/**
 * Description: Implements a data commerce with representative sample checking protocol
 */
//solium-disable linebreak-style
pragma solidity ^0.5.0;

import '../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol';

contract DataMarket {

    address payable public seller; //owner
    address payable public buyer;
    enum State { Created, Paid, SaltReleased, Challenged, SellerPaid, BuyerRefunded, Cancelled }
    State public state;

    bytes32 public MRC; //commitment del criptograma
    bytes32 public MRK; //commitment de les claus

    bytes32 public n; //no registres de la BBDD
    uint256 public price; //preu
    bytes32 public index; //index de la key pel challenge

    bytes32 public salt;

    uint256 public tpaid;
    uint256 public tsalt;
    uint256 public tchallenge;
    uint256 public timeout = 10;

    event StateInfo(State state);

    /**
     * @dev only seller
     */
    modifier onlySeller() {
        require (msg.sender == seller, 'sender does not match with seller');
        _;
    }

    /**
     * @dev only buyer
     */
    modifier onlyBuyer() {
        require (msg.sender == buyer, 'sender does not match with buyer');
        _;
    }

    /**
     * @dev State requirement
     */
    modifier inState(State _state) {
        require(state == _state, 'state does not match current state');
        _;
    }

    /**
     * @dev Secures that execution is done after a time selected
     */
    modifier onlyAfter(uint _time) {
        require(block.timestamp > _time, 'timeout not reached'); // now equival a block.timestamp
        _;
    }

    /**
     * @dev Description, N, Ncheck and price saved in the smart contract during the construction
     *
     * @param _p Hash of the description provided by the seller (deployer)
     * @param _n Number of total data samples
     * @param _MRC Number of samples to be revealed
     * @param _MRK Price of the whole data
     */
    constructor(bytes32 _n, uint256 _p, bytes32 _MRC, bytes32 _MRK) public payable {
        seller = msg.sender;
        n = _n;
        price = _p;
        MRC = _MRC;
        MRK = _MRK;
        //creation_block = block.number;
    }

    /**
     * @dev The buyer makes the payment
     */
    function payB() public payable inState(State.Created) onlyBuyer() {
        if (msg.value >= price) {
            buyer = msg.sender;
            tpaid = block.timestamp;
            state = State.Paid;
            emit StateInfo(state);
        } else {
            //Torna el pago si no es suficient
            msg.sender.transfer(msg.value);
        }
    }

    /**
     * @dev Seller reveals the salt to decrypt all the data in order to the buyer obtains it
     * @param _salt Salt revealed
     */
    function saltRelease(bytes32 _salt) public payable inState(State.Paid) onlySeller() {
        salt = _salt;
        tsalt = block.timestamp;
        state = State.SaltReleased;
        emit StateInfo(state);
    }


    /**
     * @dev Seller aborts the protocol
     *
     */
    function sellerCancel() public onlySeller{
        require(state == State.Created, 'state is not valid');
        state = State.Cancelled;
        emit StateInfo(state);
    }

    /**
     * @dev seller pays
     */
    function sellerPay() public onlySeller{
        require((state == State.SaltReleased) && (block.timestamp > tsalt + timeout), 'state is not valid');
        state = State.SellerPaid;
        emit StateInfo(state);
        selfdestruct(seller);
    }

    /**
     * @dev Buyer aborts the protocol
     */
    function buyerRefund() public onlyBuyer {
        require(((state == State.Paid) && (block.timestamp > tpaid + timeout)) || ((state == State.Challenged) && (block.timestamp > tchallenge + timeout)), 'state is not valid');
        state = State.BuyerRefunded;
        emit StateInfo(state);
    }


    /**
     * @dev challenge
     * @param _i index key
     */
    function challenge(bytes32 _i) public inState(State.SaltReleased) onlyBuyer() {
        index = _i;
        tchallenge = block.timestamp;
        state = State.Challenged;
        emit StateInfo(state);
    }

    /**
     * @dev check merkle proof
     * @param _i index
     * @param value value
     * @param _MPi merkle tree proof
     * @param root root
     */
    function checkMerkleProof(bytes32 _i, bytes32 value, bytes32[] memory _MPi, bytes32 root) private view inState(State.SaltReleased) returns (bool){
        // bytes32 c;
        bytes32 leaf = keccak256(abi.encodePacked(value));
        // TODO: Rewrite check merkle proof depending on merkle tree used
        // for (c; c < bytes32(_MPi.length); bytes32(uint(c) + 1) ) {
        //     if ((_i & (2 ** c)) == 0){
        //         leaf = keccak256(leaf.sub(_MPi[c]));
        //     }else{
        //         leaf = keccak256(_MPi[c].sub(leaf));
        //     }
        // }
        return root == leaf;
    }

    function checkFormat(bytes32[] memory value) private pure returns (bool){
        // Simplest format: first position = 0
        return value[0] == 0;
    }

    function solveComplaint(
        bytes32 _i,
        bytes32[] memory _MPKi,
        bytes32 _ci,
        bytes32[] memory _MPCi
        ) public inState(State.SaltReleased) onlyBuyer() {

        bytes32 ki = 0;
        // bytes32 ki = bytes32(keccak256(bytes32(uint(salt) + (uint(_i)))));
        bool checkMPK = checkMerkleProof(_i, ki, _MPKi, MRK);
        // bool checkF = checkFormat(_ci, ki);
        // TODO: CheckFormat ???
        if (checkMPK && checkMPK){
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
