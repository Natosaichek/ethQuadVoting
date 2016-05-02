import "/home/nato/Eth/quad/quadraticVoting/quadToken.sol";

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
    function Congress() {}
   

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
//		if (balanceOf[msg.sender] < voteStrength) throw;  // If they can't afford the vote, then abort.  TODO: somehow import knowlege of quadToken
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