pragma solidity ^0.5.0;

import "./InitializableV2.sol";


contract ServiceTypeManager is InitializableV2 {
    address governanceAddress;

    /**
     * @dev - mapping of serviceType - serviceTypeVersion
     * Example - "discovery-provider" - ["0.0.1", "0.0.2", ..., "currentVersion"]
     */
    mapping(bytes32 => bytes32[]) public serviceTypeVersions;

    /**
     * @dev - mapping of serviceType - < serviceTypeVersion, isValid >
     * Example - "discovery-provider" - <"0.0.1", true>
     */
    mapping(bytes32 => mapping(bytes32 => bool)) public serviceTypeVersionInfo;

    /// @dev List of valid service types
    bytes32[] private validServiceTypes;

    /// @dev Struct representing service type stake requirements
    struct ServiceTypeStakeRequirements {
        uint minStake;
        uint maxStake;
    }

    /// @dev mapping of service type to registered requirements
    mapping(bytes32 => ServiceTypeStakeRequirements) serviceTypeStakeRequirements;

    event SetServiceVersion(bytes32 _serviceType, bytes32 _serviceVersion);
    event Test(string msg, bool value);
    event TestAddr(string msg, address addr);
//SWC-135-Code With No Effects:L34,35
    /**
     * @notice Function to initialize the contract
     * @param _governanceAddress - Governance proxy address
     */
    function initialize(address _governanceAddress) public initializer
    {
        governanceAddress = _governanceAddress;
        InitializableV2.initialize();
    }

    /// @notice Get the Governance address
    function getGovernanceAddress() external view returns (address addr) {
        return governanceAddress;
    }

    /**
     * @notice Set the Governance address
     * @dev Only callable by Governance address
     * @param _governanceAddress - address for new Governance contract
     */
    function setGovernanceAddress(address _governanceAddress) external {
        require(msg.sender == governanceAddress, "Only governance");
        governanceAddress = _governanceAddress;
    }

    // ========================================= Service Type Logic =========================================

    /// @notice Add a new service type
    /**
     * @notice Add a new service type
     * @param _serviceType - type of service to add
     * @param _serviceTypeMin - minimum stake for service type
     * @param _serviceTypeMax - maximum stake for service type
     */
    function addServiceType(
        bytes32 _serviceType,
        uint _serviceTypeMin,
        uint _serviceTypeMax
    ) external
    {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, "Only callable by Governance contract");
        require(!this.serviceTypeIsValid(_serviceType), "Already known service type");

        validServiceTypes.push(_serviceType);
        serviceTypeStakeRequirements[_serviceType] = ServiceTypeStakeRequirements({
            minStake: _serviceTypeMin,
            maxStake: _serviceTypeMax
        });
    }

    /**
     * @notice Remove an existing service type
     * @param _serviceType - name of service type to remove
     */
    function removeServiceType(bytes32 _serviceType) external {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, "Only callable by Governance contract");

        uint serviceIndex = 0;
        bool foundService = false;
        for (uint i = 0; i < validServiceTypes.length; i ++) {
            if (validServiceTypes[i] == _serviceType) {
                serviceIndex = i;
                foundService = true;
                break;
            }
        }
        require(foundService == true, "Invalid service type, not found");
        // Overwrite service index
        uint lastIndex = validServiceTypes.length - 1;
        validServiceTypes[serviceIndex] = validServiceTypes[lastIndex];
        validServiceTypes.length--;
        // Overwrite values
        serviceTypeStakeRequirements[_serviceType].minStake = 0;
        serviceTypeStakeRequirements[_serviceType].maxStake = 0;
    }

    /**
     * @notice Update a service type
     * @param _serviceType - type of service
     * @param _serviceTypeMin - minimum stake for service type
     * @param _serviceTypeMax - maximum stake for service type
     */
    function updateServiceType(
        bytes32 _serviceType,
        uint _serviceTypeMin,
        uint _serviceTypeMax
    ) external
    {
        _requireIsInitialized();
        require(
            msg.sender == governanceAddress,
            "Only callable by Governance contract"
        );

        require(this.serviceTypeIsValid(_serviceType), "Invalid service type");

        serviceTypeStakeRequirements[_serviceType].minStake = _serviceTypeMin;
        serviceTypeStakeRequirements[_serviceType].maxStake = _serviceTypeMax;
    }

    /**
     * @notice Get min and max stake for a given service type
     * @param _serviceType - type of service
     * @return min and max stake for type
     */
    function getServiceTypeStakeInfo(bytes32 _serviceType)
    external view returns (uint min, uint max)
    {
        return (
            serviceTypeStakeRequirements[_serviceType].minStake,
            serviceTypeStakeRequirements[_serviceType].maxStake
        );
    }

    /**
     * @notice Get list of valid service types
     */
    function getValidServiceTypes()
    external view returns (bytes32[] memory types)
    {
        return validServiceTypes;
    }

    /**
     * @notice Return indicating whether this is a valid service type
     */
    function serviceTypeIsValid(bytes32 _serviceType)
    external view returns (bool isValid)
    {
        return serviceTypeStakeRequirements[_serviceType].maxStake > 0;
    }

    // ========================================= Service Version Logic =========================================

    /**
     * @notice Add new version for a serviceType
     * @param _serviceType - type of service
     * @param _serviceVersion - new version of service to add
     */
    function setServiceVersion(
        bytes32 _serviceType,
        bytes32 _serviceVersion
    ) external
    {
        _requireIsInitialized();

        require(msg.sender == governanceAddress, "Only callable by Governance contract");

        require(
            serviceTypeVersionInfo[_serviceType][_serviceVersion] == false,
            "Already registered"
        );

         // Update array of known types
        serviceTypeVersions[_serviceType].push(_serviceVersion);

        // Update status for this specific service version
        serviceTypeVersionInfo[_serviceType][_serviceVersion] = true;

        emit SetServiceVersion(_serviceType, _serviceVersion);
    }

    /**
     * @notice Get a version for a service type given it's index
     * @param _serviceType - type of service
     * @param _versionIndex - index in list of service versions
     */
    function getVersion(bytes32 _serviceType, uint _versionIndex)
    external view returns (bytes32 version)
    {
        require(
            serviceTypeVersions[_serviceType].length > _versionIndex,
            "No registered version of serviceType"
        );
        return (serviceTypeVersions[_serviceType][_versionIndex]);
    }

    /**
     * @notice Get curent version for a service type
     * @param _serviceType - type of service
     * @return Returns current version of service
     */
    function getCurrentVersion(bytes32 _serviceType)
    external view returns (bytes32 currentVersion)
    {
        require(
            serviceTypeVersions[_serviceType].length >= 1,
            "No registered version of serviceType"
        );
        uint latestVersionIndex = serviceTypeVersions[_serviceType].length - 1;
        return (serviceTypeVersions[_serviceType][latestVersionIndex]);
    }

    /**
     * @notice Get total number of versions for a service type
     * @param _serviceType - type of service
     */
    function getNumberOfVersions(bytes32 _serviceType)
    external view returns (uint)
    {
        return serviceTypeVersions[_serviceType].length;
    }

    /**
     * @notice Return boolean indicating whether given version is valid for given type
     * @param _serviceType - type of service
     * @param _serviceVersion - version of service to check
     */
    function serviceVersionIsValid(bytes32 _serviceType, bytes32 _serviceVersion)
    external view returns (bool isValidServiceVersion)
    {
        return serviceTypeVersionInfo[_serviceType][_serviceVersion];
    }
}
