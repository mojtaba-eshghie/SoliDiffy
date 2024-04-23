pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

contract AbstractProxy {
  bytes32 public app_exec_id;
  function getAdmin() external view returns (address);
}

contract AbstractIdx {
    function getAdmin(address, bytes32) external view returns (address);
}

/**
 * Registry of Proxy smart-contracts deployed from Token Wizard 2.0.
 */
contract TokenWizardProxiesRegistry is Ownable {
  address public abstractStorageAddr;
  address public mintedCappedIdxAddr;
  address public dutchIdxAddr;
  mapping (address => Crowdsale[]) private deployedCrowdsalesByUser;
  event Added(address indexed sender, address indexed proxyAddress, bytes32 appExecID);
  struct Crowdsale {
      address proxyAddress;
      bytes32 execID;
  }
  
  constructor (
    address _abstractStorage,
    address _mintedCappedIdx,
    address _dutchIdx
  ) public {
      require(_abstractStorage != address(0));
      require(_mintedCappedIdx != address(0));
      require(_dutchIdx != address(0));
      require(_abstractStorage != _mintedCappedIdx && _abstractStorage != _dutchIdx && _mintedCappedIdx != _dutchIdx);
      abstractStorageAddr = _abstractStorage;
      mintedCappedIdxAddr = _mintedCappedIdx;
      dutchIdxAddr = _dutchIdx;
  }

  function changeAbstractStorage(address newAbstractStorageAddr) public onlyOwner {
    abstractStorageAddr = newAbstractStorageAddr;
  }

  function changeMintedCappedIdx(address newMintedCappedIdxAddr) public onlyOwner {
    mintedCappedIdxAddr = newMintedCappedIdxAddr;
  }

  function changeDutchIdxAddr(address newDutchIdxAddr) public onlyOwner {
    dutchIdxAddr = newDutchIdxAddr;
  }

  function trackCrowdsale(address proxyAddress) public {
    AbstractProxy proxy = AbstractProxy(proxyAddress);
    require(proxyAddress != address(0));
    require(msg.sender == proxy.getAdmin());
    bytes32 appExecID = proxy.app_exec_id();
    AbstractIdx mintedCappedIdx = AbstractIdx(mintedCappedIdxAddr);
    AbstractIdx dutchIdx = AbstractIdx(dutchIdxAddr);
    require(mintedCappedIdx.getAdmin(abstractStorageAddr, appExecID) == msg.sender || dutchIdx.getAdmin(abstractStorageAddr, appExecID) == msg.sender);
    for (uint i = 0; i < deployedCrowdsalesByUser[msg.sender].length; i++) {
        require(deployedCrowdsalesByUser[msg.sender][i].proxyAddress != proxyAddress);
        require(deployedCrowdsalesByUser[msg.sender][i].execID != appExecID);
    }
    deployedCrowdsalesByUser[msg.sender].push(Crowdsale({proxyAddress: proxyAddress, execID: appExecID}));
    emit Added(msg.sender, proxyAddress, appExecID);
  }

  function countCrowdsalesForUser(address deployer) public view returns (uint) {
    return deployedCrowdsalesByUser[deployer].length;
  }
  
  function getCrowdsalesForUser(address deployer) public view returns (address[]) {
      address[] memory proxies = new address[](deployedCrowdsalesByUser[deployer].length);
      for (uint k = 0; k < deployedCrowdsalesByUser[deployer].length; k++) {
          proxies[k] = deployedCrowdsalesByUser[deployer][k].proxyAddress;
      }
      return proxies;
  }
}