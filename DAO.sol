// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract DAO {
    struct Proposal {
        uint256 id;
        string description;
        uint256 requestedAmount;
        address payable receiptant;
        uint256 votes;
        uint256 ends;
        bool isExecuted;
    }

    address public manager;
    uint256 duration;
    uint256 public noOfInvestors;
    uint256 public totalShares;
    uint256 public availableFunds;
    uint256 proposalId;
    uint256 votingTime;
    uint256 quorem;
    mapping(address => mapping(uint256 => bool)) public isVoted;
    mapping(address => bool) private isInvestor;
    address[] public Investors;
    mapping(address => uint256) public shares;
    mapping(uint256 => Proposal) public proposals;

    constructor(
        uint256 _duration,
        uint256 _votingTime,
        uint256 _quorem
    ) {
        require(quorem >= 0 && quorem < 100, "Invalid values");
        manager = msg.sender;
        duration = _duration;
        votingTime = _votingTime;
        quorem = _quorem;
    }

    modifier _onlyInvestor() {
        require(isInvestor[msg.sender] == true, "Only investor is acessible!");
        _;
    }
    modifier _onlyManager() {
        require(manager == msg.sender, "Only Manager is acessible!");
        _;
    }

    //Function to contribute amount and get shares according to contribution
    function contribute() public payable {
        require(duration > block.timestamp, "You exceed timeLimits");
        require(msg.value >= 1 ether, "Insufficient amount for contribution");
        if (!isInvestor[msg.sender]) {
            isInvestor[msg.sender] = true;
            Investors.push(msg.sender);
            noOfInvestors++;
        }
        shares[msg.sender] += msg.value / 10000000000000000;
        totalShares += msg.value / 10000000000000000;
        availableFunds += msg.value;
    }

    //Function that will allow to reedem the shares
    function reedemShares(uint256 _quantity) public payable _onlyInvestor {
        require(_quantity <= shares[msg.sender], "You exceed your quantity");
        shares[msg.sender] -= _quantity;
        totalShares -= _quantity;
        availableFunds -= _quantity * 10000000000000000;
        if (shares[msg.sender] == 0 && isInvestor[msg.sender]) {
            isInvestor[msg.sender] = false;
            noOfInvestors--;
        }
        payable(msg.sender).transfer(_quantity * 10000000000000000);
    }

    //Function that will allow to transfer shares to others.
    function transferShares(uint256 _quantity, address _to)
        public
        payable
        _onlyInvestor
    {
        require(totalShares >= _quantity, "Not enough shares");
        require(_quantity <= shares[msg.sender], "Quantity exceeds");
        shares[msg.sender] -= _quantity;
        if (shares[msg.sender] == 0) {
            isInvestor[msg.sender] = false;
            noOfInvestors--;
        }
        shares[_to] += _quantity;
        Investors.push(_to);
        if (!isInvestor[_to]) {
            noOfInvestors++;
        }
        isInvestor[_to] = true;
    }

    //Function to createProposals ,it is only allowed for the manager
    function createProposals(
        string calldata _description,
        uint256 _amount,
        address payable _receiptant
    ) public _onlyManager {
        require(_amount > 10, "Only can give the values more than 10");
        proposals[proposalId] = Proposal(
            proposalId,
            _description,
            _amount,
            _receiptant,
            0,
            block.timestamp + votingTime,
            false
        );
        proposalId++;
    }

    //Function that will allow to vote on proposals, only Investors are allowed.
    function voteOnProposals(uint256 _proposalId) public _onlyInvestor {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.ends > block.timestamp, "Voting time has ended");
        require(proposal.isExecuted ==false, "It is already executed");
        require(
            isVoted[msg.sender][_proposalId] ==false,
            "You have already voted for this proposal"
        );
        isVoted[msg.sender][_proposalId] = true;
        proposal.votes += shares[msg.sender];
    }

    //Function that will execute the proposal ,it is only allowed  for manager.
    function executeProposals(uint256 _proposalId) public _onlyManager {
        Proposal storage proposal = proposals[_proposalId];
        require(
            quorem <= (proposal.votes * 100) / totalShares,
            "Needs Majority to execute the proposals"
        );
        proposal.isExecuted = true;
        availableFunds -= proposal.requestedAmount;
        _transfer(proposal.requestedAmount, proposal.receiptant);
    }

    function _transfer(uint256 amount, address payable _receiptant) private {
        _receiptant.transfer(amount);
    }

    //Function to retrieve all the ProposalList we created soFar.
    function retrieveProposalList()
        public
        view
        _onlyInvestor
        returns (Proposal[] memory)
    {
        Proposal[] memory arr = new Proposal[](proposalId);
        for (uint256 i = 0; i < proposalId; i++) {
            arr[i] = proposals[i];
        }
        return arr;
    }

    //Function that will allow us to see the list of investors.
    function retrieveInvestorsList() public view returns (address[] memory) {
        return Investors;
    }
}
