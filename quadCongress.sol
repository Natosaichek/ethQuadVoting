contract QuadTokenSupply {
    /* Public variables of the token */
    string public name;
    string public symbol;
    string public version;
    uint8 public decimals;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
	event ReportBalance(address indexed accountHolder, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function QuadTokenSupply(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes ( QÍ ) ( QÍ  )
        decimals = decimalUnits;                            // Amount of decimals for display purposes
    }
		
    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }


    /* This unnamed function is called whenever someone tries to send ether to it */
    function () {
        throw;     // Prevents accidental sending of ether
    }
}

contract Congress {

	function sqrt(uint x) returns (uint y) {
		uint z = (x + 1) / 2;
		y = x;
		while (z < y) {
			y = z;
			z = (x / z + z) / 2;
    	}
	}
	
    /* Contract Variables and events */
    Proposal[] public proposals;
    uint public numProposals;
	QuadTokenSupply public supply;

    event ProposalAdded(uint proposalID, string description);
    event Voted(uint proposalID, bool position, address voter, string justification, uint256 voteStrength);
    event ProposalTallied(uint proposalID, int result, uint quorum, bool active);

	struct Proposal {
        string description;
		bool voteComplete;
        bool proposalPassed;
        uint numberOfVotes;
        int currentResult;
        Vote[] votes;
        mapping (address => bool) voted;
    }

    struct Vote {
		bool inSupport;
        uint256 voteStrength;
        address voter;
        string justification;
    }

    /* First time setup */
    function Congress(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
		) {
		this.supply = QuadTokenSupply(initialSupply, tokenName, decimalUnits, tokenSymbol);
	}


    /* Function to create a new proposal */
    function newProposal(
		string description
	)
        returns (uint proposalID)
    {
        proposalID = proposals.length++;
        Proposal p = proposals[proposalID];
        p.voteComplete = false;
        p.proposalPassed = false;
        p.numberOfVotes = 0;
		p.description = description;
        ProposalAdded(proposalID, description);
        numProposals = proposalID+1;
    }

    function vote(
		bool inSupport,
        uint proposalNumber,
        uint256 voteStrength,
        string justificationText
    )
        returns (uint voteID)
    {
        Proposal p = proposals[proposalNumber];         // Get the proposal
		if (supply.balanceOf(msg.sender) < voteStrength) throw;  // If they can't afford the vote, then abort.  TODO: somehow import knowlege of quadToken
		if (p.voted[msg.sender] == true) throw;         // If has already voted, cancel
        p.voted[msg.sender] = true;                     // Set this voter as having voted
        p.numberOfVotes++;                              // Increase the number of votes
        if (inSupport) {                         // If they support the proposal
			p.currentResult += sqrt(int[voteStrength]);  // Increase score TODO: handle fractional values
        } else {                                        // If they don't
            p.currentResult -= sqrt(int[voteStrength]);  // Decrease the score TODO: handle fractional values
        }
        // Create a log of this event
        Voted(proposalNumber,  inSupport, msg.sender, justificationText, voteStrength);
    }

    function executeProposal(uint proposalNumber) returns (int result) {
        Proposal p = proposals[proposalNumber];
        /* Check if the proposal can be executed */
		if (p.numberOfVotes < 5)  // TODO: put in a time limit?  make this number scale with the number of known voters?
            throw;
        /* execute result */
        if (p.currentResult > 0) {
            /* If difference between support and opposition is larger than margin */
            p.voteComplete = true;
            p.proposalPassed = true;
        } else {
            p.voteComplete = true;
            p.proposalPassed = false;
        }
        // Fire Events
        ProposalTallied(proposalNumber, p.currentResult, p.numberOfVotes, p.proposalPassed);
    }
}