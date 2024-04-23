import "./CrowdsaleBase.sol";
import "./AllocatedCrowdsaleMixin.sol";
import "./KYCPayloadDeserializer.sol";

/**
 * A crowdsale that allows buys only from signed payload with server-side specified limits and price.
 *
 * The token distribution happens as in the allocated crowdsale.
 *
 */
contract KYCCrowdsale is AllocatedCrowdsaleMixin, KYCPayloadDeserializer {

  /* Server holds the private key to this address to sign incoming buy payloads to signal we have KYC records in the books for these users. */
  address public signerAddress;

  /* A new server-side signer key was set to be effective */
  event SignerChanged(address signer);

  /**
   * Constructor.
   */
  function KYCCrowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal, address _beneficiary) CrowdsaleBase(_token, _pricingStrategy, _multisigWallet, _start, _end, _minimumFundingGoal) AllocatedCrowdsaleMixin(_beneficiary) {

  }

  /**
   * A token purchase with anti-money laundering
   *
   * ©return tokenAmount How many tokens where bought
   */
  function buyWithKYCData(bytes dataframe, uint8 v, bytes32 r, bytes32 s) public payable returns(uint tokenAmount) {

    uint _tokenAmount;
    uint multiplier = 10 ** 18;

    // Perform signature check for normal addresses
    // (not deployment accounts, etc.)
    if(earlyParticipantWhitelist[msg.sender]) {
      // Deployment provided early participant list is for deployment and diagnostics
      // For test purchases use this faux customer id 0x1000
      _tokenAmount = investInternal(msg.sender, 0x1000);

    } else {
      // User comes through the server, check that the signature to ensure ther server
      // side KYC has passed for this customer id and whitelisted Ethereum address

      bytes32 hash = sha256(dataframe);

      var (whitelistedAddress, customerId, minETH, maxETH, pricingInfo) = getKYCPayload(dataframe);

      // Check that the KYC data is signed by our server
      require(ecrecover(hash, v, r, s) == signerAddress);

      // Only whitelisted address can participate the transaction
      require(whitelistedAddress == msg.sender);

      // Server gives us information what is the buy price for this user
      uint256 tokensTotal = calculateTokens(msg.value, pricingInfo);

      _tokenAmount = buyTokens(msg.sender, customerId, tokensTotal);
    }

    if(!earlyParticipantWhitelist[msg.sender]) {
      // We assume there is no serious min and max fluctuations for the customer, unless
      // especially set in the server side per customer manual override.
      // Otherwise the customer can reuse old data payload with different min or max value
      // to work around the per customer cap.
      require(investedAmountOf[msg.sender] >= minETH * multiplier / 10000);
      require(investedAmountOf[msg.sender] <= maxETH * multiplier / 10000);
    }

    return _tokenAmount;
  }

  /// @dev This function can set the server side address
  /// @param _signerAddress The address derived from server's private key
  function setSignerAddress(address _signerAddress) onlyOwner {
    signerAddress = _signerAddress;
    SignerChanged(signerAddress);
  }

}
