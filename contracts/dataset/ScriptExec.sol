pragma solidity ^0.4.23;

import '../interfaces/StorageInterface.sol';
import '../interfaces/RegistryInterface.sol';

contract ScriptExec {

  /// DEFAULT VALUES ///

  address public app_storage;
  address public provider;
  bytes32 public registry_exec_id;
  address public exec_admin;

  /// APPLICATION INSTANCE METADATA ///

  struct Instance {
    address current_provider;
    bytes32 current_registry_exec_id;
    bytes32 app_exec_id;
    bytes32 app_name;
    bytes32 version_name;
  }

  // Maps the execution ids of deployed instances to the address that deployed them -
  mapping (bytes32 => address) public deployed_by;
  // Maps the execution ids of deployed instances to a struct containing their metadata -
  mapping (bytes32 => Instance) public instance_info;
  // Maps an address that deployed app instances to metadata about the deployed instance -
  mapping (address => Instance[]) public deployed_instances;
  // Maps an application name to the exec ids under which it is deployed -
  mapping (bytes32 => bytes32[]) public app_instances;

  /// EVENTS ///

  event AppInstanceCreated(address indexed creator, bytes32 indexed execution_id, bytes32 app_name, bytes32 version_name);
  event StorageException(bytes32 indexed execution_id, string message);

  // Modifier - The sender must be the contract administrator
  modifier onlyAdmin() {
    require(msg.sender == exec_admin);
    _;
  }

  // Payable function - for abstract storage refunds
  function () public payable { }


  /*
  Configure various defaults for a script exec contract
  @param _exec_admin: A privileged address, able to set the target provider and registry exec id
  @param _app_storage: The address to which applications will be stored
  @param _provider: The address under which applications have been initialized
  */
  function configure(address _exec_admin, address _app_storage, address _provider) public {
    require(_app_storage != 0, 'Invalid input');
    exec_admin = _exec_admin;
    app_storage = _app_storage;
    provider = _provider;

    if (exec_admin == 0)
      exec_admin = msg.sender;
  }

  /// APPLICATION EXECUTION ///

  bytes4 internal constant EXEC_SEL = bytes4(keccak256('exec(address,bytes32,bytes)'));

  /*
  Executes an application using its execution id and storage address.

  @param _exec_id: The instance exec id, which will route the calldata to the appropriate destination
  @param _calldata: The calldata to forward to the application
  @return success: Whether execution succeeded or not
  */
  function exec(bytes32 _exec_id, bytes _calldata) external payable returns (bool success) {
    // Call 'exec' in AbstractStorage, passing in the sender's address, the app exec id, and the calldata to forward -
    if (address(app_storage).call.value(msg.value)(abi.encodeWithSelector(
      EXEC_SEL, msg.sender, _exec_id, _calldata
    )) == false) {
      // Call failed - emit error message from storage and return 'false'
      checkErrors(_exec_id);
      // Return unspent wei to sender
      address(msg.sender).transfer(address(this).balance);
      return false;
    }

    // Get returned data
    success = checkReturn();
    // If execution failed,
    require(success, 'Execution failed');

    // Transfer any returned wei back to the sender
    address(msg.sender).transfer(address(this).balance);
  }

  bytes4 internal constant ERR = bytes4(keccak256('Error(string)'));

  // Return the bytes4 action requestor stored at the pointer, and cleans the remaining bytes
  function getAction(uint _ptr) internal pure returns (bytes4 action) {
    assembly {
      // Get the first 4 bytes stored at the pointer, and clean the rest of the bytes remaining
      action := and(mload(_ptr), 0xffffffff00000000000000000000000000000000000000000000000000000000)
    }
  }

  // Checks to see if an error message was returned with the failed call, and emits it if so -
  function checkErrors(bytes32 _exec_id) internal {
    // If the returned data begins with selector 'Error(string)', get the contained message -
    string memory message;
    bytes4 err_sel = ERR;
    assembly {
      // Get pointer to free memory, place returned data at pointer, and update free memory pointer
      let ptr := mload(0x40)
      returndatacopy(ptr, 0, returndatasize)
      mstore(0x40, add(ptr, returndatasize))

      // Check value at pointer for equality with Error selector -
      if eq(mload(ptr), and(err_sel, 0xffffffff00000000000000000000000000000000000000000000000000000000)) {
        message := add(0x24, ptr)
      }
    }
    // If no returned message exists, emit a default error message. Otherwise, emit the error message
    if (bytes(message).length == 0)
      emit StorageException(_exec_id, "No error recieved");
    else
      emit StorageException(_exec_id, message);
  }

  // Checks data returned by an application and returns whether or not the execution changed state
  function checkReturn() internal pure returns (bool success) {
    success = false;
    assembly {
      // returndata size must be 0x60 bytes
      if eq(returndatasize, 0x60) {
        // Copy returned data to pointer and check that at least one value is nonzero
        let ptr := mload(0x40)
        returndatacopy(ptr, 0, returndatasize)
        if iszero(iszero(mload(ptr))) { success := 1 }
        if iszero(iszero(mload(add(0x20, ptr)))) { success := 1 }
        if iszero(iszero(mload(add(0x40, ptr)))) { success := 1 }
      }
    }
    return success;
  }

  /// APPLICATION INITIALIZATION ///

  /*
  Initializes an instance of an application. Uses default app provider and registry app.
  Uses latest app version by default.
  @param _app_name: The name of the application to initialize
  @param _init_calldata: Calldata to be forwarded to the application's initialization function
  @return exec_id: The execution id (within the application's storage) of the created application instance
  @return version: The name of the version of the instance
  */
  function createAppInstance(bytes32 _app_name, bytes _init_calldata) external returns (bytes32 exec_id, bytes32 version) {
    require(_app_name != 0 && _init_calldata.length >= 4, 'invalid input');
    (exec_id, version) = StorageInterface(app_storage).createInstance(
      msg.sender, _app_name, provider, registry_exec_id, _init_calldata
    );
    // Set various app metadata values -
    deployed_by[exec_id] = msg.sender;
    app_instances[_app_name].push(exec_id);
    Instance memory inst = Instance(
      provider, registry_exec_id, exec_id, _app_name, version
    );
    instance_info[exec_id] = inst;
    deployed_instances[msg.sender].push(inst);
    // Emit event -
    emit AppInstanceCreated(msg.sender, exec_id, _app_name, version);
  }

  /// ADMIN FUNCTIONS ///

  /*
  Allows the exec admin to set the registry exec id from which applications will be initialized -
  @param _exec_id: The new exec id from which applications will be initialized
  */
  function setRegistryExecID(bytes32 _exec_id) public onlyAdmin() {
    registry_exec_id = _exec_id;
  }

  /*
  Allows the exec admin to set the provider from which applications will be initialized in the given registry exec id
  @param _provider: The address under which applications to initialize are registered
  */
  function setProvider(address _provider) public onlyAdmin() {
    provider = _provider;
  }

  // Allows the admin to set a new admin address
  function setAdmin(address _admin) public onlyAdmin() {
    require(_admin != 0);
    exec_admin = _admin;
  }

  /// STORAGE GETTERS ///

  // Returns a list of execution ids under which the given app name was deployed
  function getInstances(bytes32 _app_name) public view returns (bytes32[] memory) {
    return app_instances[_app_name];
  }

  /*
  Returns the number of instances an address has created
  @param _deployer: The address that deployed the instances
  @return uint: The number of instances deployed by the deployer
  */
  function getDeployedLength(address _deployer) public view returns (uint) {
    return deployed_instances[_deployer].length;
  }

  // The function selector for a simple registry 'registerApp' function
  bytes4 internal constant REGISTER_APP_SEL = bytes4(keccak256('registerApp(bytes32,address,bytes4[],address[])'));

  /*
  Returns the index address and implementing address for the simple registry app set as the default
  @return indx: The index address for the registry application - contains getters for the Registry, as well as its init funciton
  @return implementation: The address implementing the registry's functions
  */
  function getRegistryImplementation() public view returns (address indx, address implementation) {
    indx = StorageInterface(app_storage).getIndex(registry_exec_id);
    implementation = StorageInterface(app_storage).getTarget(registry_exec_id, REGISTER_APP_SEL);
  }

  /*
  Returns the functions and addresses implementing those functions that make up an application under the give execution id
  @param _exec_id: The execution id that represents the application in storage
  @return index: The index address of the instance - holds the app's getter functions and init functions
  @return functions: A list of function selectors supported by the application
  @return implementations: A list of addresses corresponding to the function selectors, where those selectors are implemented
  */
  function getInstanceImplementation(bytes32 _exec_id) public view
  returns (address index, bytes4[] memory functions, address[] memory implementations) {
    Instance memory app = instance_info[_exec_id];
    index = StorageInterface(app_storage).getIndex(app.current_registry_exec_id);
    (index, functions, implementations) = RegistryInterface(index).getVersionImplementation(
      app_storage, app.current_registry_exec_id, app.current_provider, app.app_name, app.version_name
    );
  }
}
