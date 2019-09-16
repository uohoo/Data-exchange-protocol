/* solium-disable linebreak-style */
pragma solidity ^0.5.0;

import "./lib/DataMarketHelpers.sol";

/**
 * Description: Implements a data commerce with representative sample checking protocol
 */
contract DataMarket is DataMarketHelpers{

    address payable public seller; //owner
    address payable public buyer;
    enum State { Created, Paid, SaltReleased, Challenged, SellerPaid, BuyerRefunded, Cancelled }
    State public state;

    bytes32 public root_cryptogram; //commitment del criptograma
    bytes32 public root_keys; //commitment de les claus

    uint256 public num_samples; //num registres de la BBDD
    uint256 public price; //preu
    bytes32 public index; //index de la key pel challenge

    bytes32 public salt; //seed, decrypt all the samples

    uint256 public block_paid; //Block which the payment is sent
    uint256 public block_salt_revealed; //Block which the salt is revealed/sent
    uint256 public block_challenged; //Block which challenge is sent
    uint256 public nblocks_timeout; //Max number of blocks to execute action

    event StateInfo(State state);

    /**
     * @dev Retrieve block number
     * @return current block number
     */
    function getBlockNumber() public view returns (uint) {
        return block.number;
    }

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
    modifier onlyAfter(uint256 _block) {
        require(getBlockNumber() > _block, 'timeout not reached'); // now equival a block.timestamp
        _;
    }

    /**
     * @dev Merkle root of the cryptograms, Merkle root of the keys, N and price saved in the smart contract during the construction
     *
     * @param _n Number of samples to be revealed
     * @param _p Price of the whole data
     * @param _MRC Merkle root of the cryptograms
     * @param _MRK Merkle root of the keys
     */
    constructor(uint256 _n,
      uint256 _p,
      bytes32 _MRC,
      bytes32 _MRK,
      address _poseidonContract
    ) public DataMarketHelpers(_poseidonContract){
        seller = msg.sender;
        num_samples = _n;
        price = _p;
        root_cryptogram = _MRC;
        root_keys = _MRK;
        //creation_block = getBlockNumber();
    }

    /**
     * @dev The buyer makes the payment
     */
    function payB() public payable inState(State.Created) onlyBuyer() {
        if (msg.value >= price) {
            buyer = msg.sender;
            block_paid = getBlockNumber();
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
        block_salt_revealed = getBlockNumber();
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
        require((state == State.SaltReleased) && (getBlockNumber() > block_salt_revealed + nblocks_timeout), 'state is not valid');
        state = State.SellerPaid;
        emit StateInfo(state);
        selfdestruct(seller);
    }

    /**
     * @dev Buyer aborts the protocol and is reimbursed
     */
    function buyerRefund() public onlyBuyer {
        require(((state == State.Paid) && (getBlockNumber() > block_paid + nblocks_timeout)), 'state is not valid');
        //  ||((state == State.Challenged) && (getBlockNumber() > block_challenged + nblocks_timeout)), 'state is not valid');
        state = State.BuyerRefunded;
        emit StateInfo(state);
    }

    /**
     * @dev The buyer sents a sample(i), ki and MPKi that the SC must check. If the buyer is right the paid is reimbursed and if not the seller gets the payment.
     * @param _i index key
     * @param _ki failing key
     * @param _MPKi the merkle proof for the affected key
     */
    function challenge(uint256 _i,bytes32 _ki, uint256[] memory _MPKi) public inState(State.SaltReleased) onlyBuyer() {
        bytes32 ki = keccak256(abi.encodePacked(salt, _ki));
        bool checkMPK = smtVerifier(uint256(root_keys), _MPKi, _i, uint256(ki), 0, 0, false, false, 24);
        if (checkMPK == false){
            state = State.BuyerRefunded;
            emit StateInfo(state);
            selfdestruct(buyer);
        }else{
            state = State.SellerPaid;
            emit StateInfo(state);
            selfdestruct(seller);
        }
        emit StateInfo(state);
    }
}
