// SWC-108-State Variable Default Visibility: L2-L725
// SWC-103-Floating Pragma: L3
pragma solidity 0.5.0;
pragma experimental ABIEncoderV2;

import "./inherited/ERC20Token.sol";
import "./inherited/ERC721Basic.sol";

/// @title StandardBounties
/// @dev A contract for issuing bounties on Ethereum paying in ETH, ERC20, or ERC721 tokens
/// @author Mark Beylin <mark.beylin@consensys.net>, Gonçalo Sá <goncalo.sa@consensys.net>, Kevin Owocki <kevin.owocki@consensys.net>, Ricardo Guilherme Schmidt (@3esmit), Matt Garnett <matt.garnett@consensys.net>, Craig Williams <craig.williams@consensys.net>
contract StandardBounties {

  /*
   * Structs
   */

  struct Bounty {
    address payable [] issuers; // An array of individuals who have complete control over the bounty, and can edit any of its parameters
    address [] approvers; // An array of individuals who are allowed to accept the fulfillments for a particular bounty
    uint deadline; // The Unix timestamp before which all submissions must be made, and after which refunds may be processed
    address token; // The address of the token associated with the bounty (should be disregarded if the tokenVersion is 0)
    uint tokenVersion; // The version of the token being used for the bounty (0 for ETH, 20 for ERC20, 721 for ERC721)
    uint balance; // The number of tokens which the bounty is able to pay out or refund
    bool hasPaidOut; // A boolean storing whether or not the bounty has paid out at least once, meaning refunds are no longer allowed
    Fulfillment [] fulfillments; // An array of Fulfillments which store the various submissions which have been made to the bounty
    Contribution [] contributions; // An array of Contributions which store the contributions which have been made to the bounty
  }

  struct Fulfillment {
    address payable [] fulfillers; // An array of addresses who should receive payouts for a given submission
    address submitter; // The address of the individual who submitted the fulfillment, who is able to update the submission as needed
  }

  struct Contribution {
    address payable contributor; // The address of the individual who contributed
    uint amount; // The amount of tokens the user contributed
    bool refunded; // A boolean storing whether or not the contribution has been refunded yet
  }

  /*
   * Storage
   */

  uint public numBounties; // An integer storing the total number of bounties in the contract
  mapping(uint => Bounty) public bounties; // A mapping of bountyIDs to bounties
  // SWC-108-State Variable Default Visibility: L48-L49
  address owner; // The address of the individual who's allowed to set the metaTxRelayer address
  address metaTxRelayer; // The address of the meta transaction relayer whose _sender is automatically trusted for all contract calls


  /*
   * Modifiers
   */

  modifier validateBountyArrayIndex(
    uint _index)
  {
    require(_index < numBounties);
    _;
  }

  modifier validateContributionArrayIndex(
    uint _bountyId,
    uint _index)
  {
    require(_index < bounties[_bountyId].contributions.length);
    _;
  }

  modifier validateFulfillmentArrayIndex(
    uint _bountyId,
    uint _index)
  {
    require(_index < bounties[_bountyId].fulfillments.length);
    _;
  }

  modifier validateIssuerArrayIndex(
    uint _bountyId,
    uint _index)
  {
    require(_index < bounties[_bountyId].issuers.length || _index == 0);
    _;
  }

  modifier validateApproverArrayIndex(
    uint _bountyId,
    uint _index)
  {
    require(_index < bounties[_bountyId].approvers.length || _index == 0);
    _;
  }

  modifier onlyIssuer(
  address _sender,
  uint _bountyId,
  uint _issuerId)
  {
  require(_sender == bounties[_bountyId].issuers[_issuerId]);
  _;
  }

  modifier onlySubmitter(
    address _sender,
    uint _bountyId,
    uint _fulfillmentId)
  {
    require(_sender ==
            bounties[_bountyId].fulfillments[_fulfillmentId].submitter);
    _;
  }

  modifier onlyContributor(
  address _sender,
  uint _bountyId,
  uint _contributionId)
  {
    require(_sender ==
            bounties[_bountyId].contributions[_contributionId].contributor);
    _;
  }

  modifier isApprover(
    address _sender,
    uint _bountyId,
    uint _approverId)
  {
    require(_sender == bounties[_bountyId].approvers[_approverId]);
    _;
  }

  modifier hasNotPaid(
    uint _bountyId)
  {
    require(!bounties[_bountyId].hasPaidOut);
    _;
  }

  modifier hasNotRefunded(
    uint _bountyId,
    uint _contributionId)
  {
    require(!bounties[_bountyId].contributions[_contributionId].refunded);
    _;
  }

  modifier senderIsValid(
    address _sender)
  {
    require(msg.sender == _sender || msg.sender == metaTxRelayer);
    _;
  }

 /*
  * Public functions
  */

  constructor() public {
    // The owner of the contract is automatically designated to be the deployer of the contract
    owner = msg.sender;
  }

  /// @dev setMetaTxRelayer(): Sets the address of the meta transaction relayer
  /// @param _relayer the address of the relayer
  function setMetaTxRelayer(address _relayer)
    public
  {
    require(msg.sender == owner); // Checks that only the owner can call
    require(metaTxRelayer == address(0)); // Ensures the meta tx relayer can only be set once
    metaTxRelayer = _relayer;
  }

  /// @dev issueBounty(): creates a new bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _issuers the array of addresses who will be the issuers of the bounty
  /// @param _approvers the array of addresses who will be the approvers of the bounty
  /// @param _data the IPFS hash representing the JSON object storing the details of the bounty (see docs for schema details)
  /// @param _deadline the timestamp which will become the deadline of the bounty
  /// @param _token the address of the token which will be used for the bounty
  /// @param _tokenVersion the version of the token being used for the bounty (0 for ETH, 20 for ERC20, 721 for ERC721)
  /// @param _depositAmount the amount of tokens being deposited to the bounty, which will create a new contribution to the bounty
  function issueBounty(
    address payable _sender,
    address payable [] memory _issuers,
    address [] memory _approvers,
    string memory _data,
    uint _deadline,
    address _token,
    uint _tokenVersion,
    uint _depositAmount)
    public
    payable
    senderIsValid(_sender)
    returns (uint)
  {
    require(_tokenVersion == 0 || _tokenVersion == 20 || _tokenVersion == 721); // Ensures a bounty can only be issued with a valid token version

    uint bountyId = numBounties; // The next bounty's index will always equal the number of existing bounties

    Bounty storage newBounty = bounties[bountyId];
    newBounty.issuers = _issuers;
    newBounty.approvers = _approvers;
    newBounty.deadline = _deadline;
    newBounty.token = _token;
    newBounty.tokenVersion = _tokenVersion;

    numBounties++; // Increments the number of bounties, since a new one has just been added

    emit BountyIssued(bountyId,
    _sender,
    _issuers,
    _approvers,
    _data, // Instead of storing the string on-chain, it is emitted within the event for easy off-chain consumption
    _deadline,
    _token,
    _tokenVersion);

    // If the issuer wants to make a contribution while they issue the bounty, trigger that call
    if (_depositAmount > 0){
      contribute(_sender, bountyId, _depositAmount);
    }
    return (bountyId);
  }

  /// @dev contribute(): Allows users to contribute tokens to a given bounty.
  ///                    Contributing merits no privelages to administer the
  ///                    funds in the bounty or accept submissions. Contributions
  ///                    are refundable but only on the condition that the deadline
  ///                    has elapsed, and the bounty has not yet paid out any funds.
  ///                    All funds deposited in a bounty are at the mercy of a
  ///                    bounty's issuers and approvers, so please be careful!
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _amount the amount of tokens being contributed
  function contribute(
    address payable _sender,
    uint _bountyId,
    uint _amount)
    public
    payable
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
  {
    // SWC-108-State Variable Default Visibility: L246-L265
    bounties[_bountyId].contributions.push(
      Contribution(_sender, _amount, false)); // Adds the contribution to the bounty
    // SWC-101-Integer Overflow and Underflow: L249
    bounties[_bountyId].balance += _amount; // Increments the balance of the bounty

    require(_amount > 0); // Contributions of the amount 0 should fail

    if (bounties[_bountyId].tokenVersion == 0){
      require(msg.value == _amount);
    } else if (bounties[_bountyId].tokenVersion == 20) {
      require(msg.value == 0); // Ensures users don't accidentally send ETH alongside a token contribution, locking up funds
      require(ERC20Token(bounties[_bountyId].token).transferFrom(_sender,
                                                                 address(this),
                                                                 _amount));
    } else if (bounties[_bountyId].tokenVersion == 721) {
      require(msg.value == 0); // Ensures users don't accidentally send ETH alongside a token contribution, locking up funds
      ERC721BasicToken(bounties[_bountyId].token).transferFrom(_sender,
                                                               address(this),
                                                               _amount);
    }

    emit ContributionAdded(_bountyId,
                           bounties[_bountyId].contributions.length - 1, // The new contributionId
                           _sender,
                           _amount);
  }

  /// @dev refundContribution(): Allows users to refund the contributions they've
  ///                            made to a particular bounty, but only if the bounty
  ///                            has not yet paid out, and the deadline has elapsed.
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _contributionId the index of the contribution being refunded
  function refundContribution(
    address _sender,
    uint _bountyId,
    uint _contributionId)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateContributionArrayIndex(_bountyId, _contributionId)
    onlyContributor(_sender, _bountyId, _contributionId)
    hasNotPaid(_bountyId)
    hasNotRefunded(_bountyId, _contributionId)
  {
    require(now > bounties[_bountyId].deadline); // Refunds may only be processed after the deadline has elapsed

    Contribution storage contribution =
      bounties[_bountyId].contributions[_contributionId];

    contribution.refunded = true;
    bounties[_bountyId].balance -= contribution.amount;

    transferTokens(_bountyId, contribution.contributor, contribution.amount); // Performs the disbursal of tokens to the contributor

    emit ContributionRefunded(_bountyId, _contributionId);
  }

  /// @dev refundContributions(): Allows users to refund their contributions in bulk
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _contributionIds the array of indexes of the contributions being refunded
  function refundContributions(
    address _sender,
    uint _bountyId,
    uint [] memory _contributionIds)
    public
    senderIsValid(_sender)
  {
    for (uint i = 0; i < _contributionIds.length; i++){
      refundContribution(_sender, _bountyId, _contributionIds[i]);
    }
  }

  /// @dev performAction(): Allows users to perform any generalized action
  ///                       associated with a particular bounty, such as applying for it
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _data the IPFS hash corresponding to a JSON object which contains the details of the action being performed (see docs for schema details)
  function performAction(
    address _sender,
    uint _bountyId,
    string memory _data)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
  {
    emit ActionPerformed(_bountyId, _sender, _data); // The _data string is emitted in an event for easy off-chain consumption
  }

  /// @dev fulfillBounty(): Allows users to fulfill the bounty to get paid out
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _fulfillers the array of addresses which will receive payouts for the submission
  /// @param _data the IPFS hash corresponding to a JSON object which contains the details of the submission (see docs for schema details)
  function fulfillBounty(
    address _sender,
    uint _bountyId,
    address payable [] memory  _fulfillers,
    string memory _data)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
  {
    require(now < bounties[_bountyId].deadline); // Submissions are only allowed to be made before the deadline
    require(_fulfillers.length > 0); // Submissions with no fulfillers would mean no one gets paid out

    bounties[_bountyId].fulfillments.push(Fulfillment(_fulfillers, _sender));

    emit BountyFulfilled(_bountyId,
                         (bounties[_bountyId].fulfillments.length - 1),
                         _fulfillers,
                         _data, // The _data string is emitted in an event for easy off-chain consumption
                         _sender);
  }

  /// @dev updateFulfillment(): Allows the submitter of a fulfillment to update their submission
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _fulfillmentId the index of the fulfillment
  /// @param _fulfillers the new array of addresses which will receive payouts for the submission
  /// @param _data the new IPFS hash corresponding to a JSON object which contains the details of the submission (see docs for schema details)
  function updateFulfillment(
  address _sender,
  uint _bountyId,
  uint _fulfillmentId,
  address payable [] memory _fulfillers,
  string memory _data)
  public
  senderIsValid(_sender)
  validateBountyArrayIndex(_bountyId)
  validateFulfillmentArrayIndex(_bountyId, _fulfillmentId)
  onlySubmitter(_sender, _bountyId, _fulfillmentId) // Only the original submitter of a fulfillment may update their submission
  {
    bounties[_bountyId].fulfillments[_bountyId].fulfillers = _fulfillers;
    emit FulfillmentUpdated(_bountyId,
                            _fulfillmentId,
                            _fulfillers,
                            _data); // The _data string is emitted in an event for easy off-chain consumption
  }

  /// @dev acceptFulfillment(): Allows any of the approvers to accept a given submission
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _fulfillmentId the index of the fulfillment to be accepted
  /// @param _approverId the index of the approver which is making the call
  /// @param _tokenAmounts the array of token amounts which will be paid to the
  ///                      fulfillers, whose length should equal the length of the
  ///                      _fulfillers array of the submission. If the bounty pays
  ///                      in ERC721 tokens, then these should be the token IDs
  ///                      being sent to each of the individual fulfillers
  function acceptFulfillment(
    address _sender,
    uint _bountyId,
    uint _fulfillmentId,
    uint _approverId,
    uint[] memory _tokenAmounts)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateFulfillmentArrayIndex(_bountyId, _fulfillmentId)
    isApprover(_sender, _bountyId, _approverId)
  {
    // now that the bounty has paid out at least once, refunds are no longer possible
    bounties[_bountyId].hasPaidOut = true;

    Fulfillment storage fulfillment =
      bounties[_bountyId].fulfillments[_fulfillmentId];

    require(_tokenAmounts.length == fulfillment.fulfillers.length); // Each fulfiller should get paid some amount of tokens (this can be 0)

    for (uint256 i = 0; i < fulfillment.fulfillers.length; i++){
      // for each fulfiller associated with the submission
      require(bounties[_bountyId].balance >= _tokenAmounts[i]); // Checks that the bounty has a sufficient balance to make the payout

      bounties[_bountyId].balance -= _tokenAmounts[i];

      if (_tokenAmounts[i] != 0){
        transferTokens(_bountyId, fulfillment.fulfillers[i], _tokenAmounts[i]);
      }
    }
    emit FulfillmentAccepted(_bountyId,
                             _fulfillmentId,
                             _sender,
                             _tokenAmounts);
  }

  /// @dev fulfillAndAccept(): Allows any of the approvers to fulfill and accept a submission simultaneously
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _fulfillers the array of addresses which will receive payouts for the submission
  /// @param _data the IPFS hash corresponding to a JSON object which contains the details of the submission (see docs for schema details)
  /// @param _approverId the index of the approver which is making the call
  /// @param _tokenAmounts the array of token amounts which will be paid to the
  ///                      fulfillers, whose length should equal the length of the
  ///                      _fulfillers array of the submission. If the bounty pays
  ///                      in ERC721 tokens, then these should be the token IDs
  ///                      being sent to each of the individual fulfillers
  function fulfillAndAccept(
    address _sender,
    uint _bountyId,
    address payable [] memory _fulfillers,
    string memory _data,
    uint _approverId,
    uint[] memory _tokenAmounts)
    public
    senderIsValid(_sender)
  {
    // first fulfills the bounty on behalf of the fulfillers
    fulfillBounty(_sender, _bountyId, _fulfillers, _data);

    // then accepts the fulfillment
    acceptFulfillment(_sender,
                      _bountyId,
                      bounties[_bountyId].fulfillments.length - 1,
                      _approverId,
                      _tokenAmounts);
  }



  /// @dev changeBounty(): Allows any of the issuers to change the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _issuers the new array of addresses who will be the issuers of the bounty
  /// @param _approvers the new array of addresses who will be the approvers of the bounty
  /// @param _data the new IPFS hash representing the JSON object storing the details of the bounty (see docs for schema details)
  /// @param _deadline the new timestamp which will become the deadline of the bounty
  function changeBounty(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    address payable [] memory _issuers,
    address payable [] memory _approvers,
    string memory _data,
    uint _deadline)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    bounties[_bountyId].issuers = _issuers;
    bounties[_bountyId].approvers = _approvers;
    bounties[_bountyId].deadline = _deadline;
    emit BountyChanged(_bountyId,
                       _sender,
                       _issuers,
                       _approvers,
                       _data,
                       _deadline);
  }

  /// @dev changeIssuer(): Allows any of the issuers to change a particular issuer of the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _issuerIdToChange the index of the issuer who is being changed
  /// @param _newIssuer the address of the new issuer
  function changeIssuer(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    uint _issuerIdToChange,
    address payable _newIssuer)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    validateIssuerArrayIndex(_bountyId, _issuerIdToChange)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    bounties[_bountyId].issuers[_issuerIdToChange] = _newIssuer;

    emit BountyIssuerChanged(_bountyId, _sender, _issuerId, _newIssuer);
  }

  /// @dev changeApprover(): Allows any of the issuers to change a particular approver of the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _approverId the index of the approver who is being changed
  /// @param _approver the address of the new approver
  function changeApprover(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    uint _approverId,
    address payable _approver)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
    validateApproverArrayIndex(_bountyId, _approverId)
  {
    bounties[_bountyId].approvers[_approverId] = _approver;

    emit BountyApproverChanged(_bountyId,
              msg.sender,
              _approverId,
              _approver);
  }

  /// @dev changeData(): Allows any of the issuers to change the data the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _data the new IPFS hash representing the JSON object storing the details of the bounty (see docs for schema details)
  function changeData(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    string memory _data)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    emit BountyDataChanged(_bountyId, msg.sender, _data); // The new _data is emitted within an event rather than being stored on-chain for minimized gas costs
  }

  /// @dev changeDeadline(): Allows any of the issuers to change the deadline the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _deadline the new timestamp which will become the deadline of the bounty
  function changeDeadline(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    uint _deadline)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    bounties[_bountyId].deadline = _deadline;

    emit BountyDeadlineChanged(_bountyId, _sender, _deadline);
  }

  /// @dev addIssuers(): Allows any of the issuers to add more issuers to the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _issuers the array of addresses to add to the list of valid issuers
  function addIssuers(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    address payable [] memory _issuers)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    for (uint i = 0; i < _issuers.length; i++){
      bounties[_bountyId].issuers.push(_issuers[i]);
    }
    emit BountyIssuersAdded(_bountyId, _sender, _issuers);
  }

  /// @dev replaceIssuers(): Allows any of the issuers to replace the issuers of the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _issuers the array of addresses to replace the list of valid issuers
  function replaceIssuers(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    address payable [] memory _issuers)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    bounties[_bountyId].issuers = _issuers;

    emit BountyIssuersReplaced(_bountyId, _sender, _issuers);
  }

  /// @dev addApprovers(): Allows any of the issuers to add more approvers to the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _approvers the array of addresses to add to the list of valid approvers
  function addApprovers(
  address _sender,
  uint _bountyId,
  uint _issuerId,
  address [] memory _approvers)
  public
  senderIsValid(_sender)
  validateBountyArrayIndex(_bountyId)
  validateIssuerArrayIndex(_bountyId, _issuerId)
  onlyIssuer(_sender, _bountyId, _issuerId)
  {
    for (uint i = 0; i < _approvers.length; i++){
      bounties[_bountyId].approvers.push(_approvers[i]);
    }
    emit BountyApproversAdded(_bountyId, _sender, _approvers);
  }

  /// @dev replaceApprovers(): Allows any of the issuers to replace the approvers of the bounty
  /// @param _sender the sender of the transaction issuing the bounty (should be the same as msg.sender unless the txn is called by the meta tx relayer)
  /// @param _bountyId the index of the bounty
  /// @param _issuerId the index of the issuer who is calling the function
  /// @param _approvers the array of addresses to replace the list of valid approvers
  function replaceApprovers(
  address _sender,
  uint _bountyId,
  uint _issuerId,
  address [] memory _approvers)
  public
  senderIsValid(_sender)
  validateBountyArrayIndex(_bountyId)
  validateIssuerArrayIndex(_bountyId, _issuerId)
  onlyIssuer(_sender, _bountyId, _issuerId)
  {
    bounties[_bountyId].approvers = _approvers;

    emit BountyApproversReplaced(_bountyId, _sender, _approvers);
  }

  /// @dev getBounty(): Returns the details of the bounty
  /// @param _bountyId the index of the bounty
  /// @return Returns a tuple for the bounty
  function getBounty(uint _bountyId)
    public
    view
    returns (Bounty memory)
  {
    return bounties[_bountyId];
  }


  function transferTokens(uint _bountyId, address payable _to, uint _amount)
    internal
  {
    if (bounties[_bountyId].tokenVersion == 0){
      _to.transfer(_amount);
    } else if (bounties[_bountyId].tokenVersion == 20) {
      require(ERC20Token(bounties[_bountyId].token).transfer(_to, _amount));
    } else if (bounties[_bountyId].tokenVersion == 721) {
      ERC721BasicToken(bounties[_bountyId].token).safeTransferFrom(address(this),
                                                                   _to,
                                                                   _amount);
    } else {
      revert();
    }
  }

  /*
   * Events
   */

  event BountyIssued(uint _bountyId, address payable _creator, address payable [] _issuers, address [] _approvers, string _data, uint _deadline, address _token, uint _tokenVersion);
  event ContributionAdded(uint _bountyId, uint _contributionId, address payable _contributor, uint _amount);
  event ContributionRefunded(uint _bountyId, uint _contributionId);
  event ActionPerformed(uint _bountyId, address _fulfiller, string _data);
  event BountyFulfilled(uint _bountyId, uint _fulfillmentId, address payable [] _fulfillers, string _data, address _submitter);
  event FulfillmentUpdated(uint _bountyId, uint _fulfillmentId, address payable [] _fulfillers, string _data);
  event FulfillmentAccepted(uint _bountyId, uint  _fulfillmentId, address _approver, uint[] _tokenAmounts);
  event BountyChanged(uint _bountyId, address _changer, address payable [] _issuers, address payable [] _approvers, string _data, uint _deadline);
  event BountyIssuerChanged(uint _bountyId, address _changer, uint _issuerId, address payable _issuer);
  event BountyIssuersAdded(uint _bountyId, address _changer, address payable [] _issuers);
  event BountyIssuersReplaced(uint _bountyId, address _changer, address payable [] _issuers);
  event BountyApproverChanged(uint _bountyId, address payable _changer, uint _approverId, address payable _approver);
  event BountyApproversAdded(uint _bountyId, address _changer, address [] _approvers);
  event BountyApproversReplaced(uint _bountyId, address _changer, address [] _approvers);
  event BountyDataChanged(uint _bountyId, address _changer, string _data);
  event BountyDeadlineChanged(uint _bountyId, address _changer, uint _deadline);
}
