/**
 * Description: Implements a data commerce with representative sample checking protocol
 */
//solium-disable linebreak-style
pragma solidity ^0.5.0;

import '../node_modules/openzeppelin-solidity/contracts/cryptography/MerkleProof.sol';

contract DataMarket {

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
    modifier onlyAfter(uint block) {
        require(block.number > block, 'timeout not reached'); // now equival a block.timestamp
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
    constructor(uint256 _n, uint256 _p, bytes32 _MRC, bytes32 _MRK) public payable {
        seller = msg.sender;
        num_samples = _n;
        price = _p;
        root_cryptogram = _MRC;
        root_keys = _MRK;
        //creation_block = block.number;
    }

    /**
     * @dev The buyer makes the payment
     */
    function payB() public payable inState(State.Created) onlyBuyer() {
        if (msg.value >= price) {
            buyer = msg.sender;
            block_paid = block.number;
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
        block_salt_revealed = block.number;
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
        require((state == State.SaltReleased) && (block.number > block_salt_revealed + nblocks_timeout), 'state is not valid');
        state = State.SellerPaid;
        emit StateInfo(state);
        selfdestruct(seller);
    }

    /**
     * @dev Buyer aborts the protocol
     */
    function buyerRefund() public onlyBuyer {
        require(((state == State.Paid) && (block.number > block_paid + nblocks_timeout)) ||
         ((state == State.Challenged) && (block.number > block_challenged + nblocks_timeout)), 'state is not valid');
        state = State.BuyerRefunded;
        emit StateInfo(state);
    }


    /**
     * @dev challenge
     * @param _i index key
     */
    function challenge(bytes32 _i) public inState(State.SaltReleased) onlyBuyer() {
        index = _i;
        block_challenged = block.number;
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
    function checkMerkleProof(bytes32 _i, bytes32 value, bytes32[] memory _MPi, bytes32 root)
     private view inState(State.SaltReleased) returns (bool){
        // bytes32 c;
        bytes32 leaf = keccak256(abi.encodePacked(value));

        // verify();

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
