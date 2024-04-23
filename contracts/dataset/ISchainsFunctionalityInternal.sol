pragma solidity ^0.5.0;

interface ISchainsFunctionalityInternal {
    function getNodesDataFromTypeOfSchain(uint typeOfSchain) external view returns (uint, uint8);
    function createGroupForSchain(
        string calldata schainName,
        bytes32 schainId,
        uint numberOfNodes,
        uint8 partOfNode) external;
    function findSchainAtSchainsForNode(uint nodeIndex, bytes32 schainId) external view returns (uint);
    function deleteGroup(bytes32 groupIndex) external;
    function replaceNode(uint nodeIndex, bytes32 groupIndex) external returns (uint);
    function selectNewNode(bytes32 groupHash) external returns (uint);
    function removeNodeFromSchain(uint nodeIndex, bytes32 groupHash) external;
    function excludeNodeFromSchain(uint nodeIndex, bytes32 groupHash) external;
    function isEnoughNodes(bytes32 groupIndex) external view returns (uint[] memory);
}