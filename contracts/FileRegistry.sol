// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";

/**
 * @title FileRegistry for GhostShare.xyz
 * @author Joris Zierold
 * @dev Main contract, which handles file tracing and access control.
 */
contract FileRegistry is ERC2771Context {
    /* ------------------------------ DATA STORAGE ------------------------------ */
    struct File {
        address fileOwner;
        mapping(address => bool) accessRights;
    }

    mapping(bytes32 => File) public files;

    /* --------------------------------- EVENTS --------------------------------- */
    event FileRegistered(bytes32 fileId, address indexed fileOwner);
    event AccessGranted(bytes32 fileId, address indexed recipient);
    event AccessRevoked(bytes32 fileId, address indexed recipient);

    /* -------------------------------- MODIFIERS ------------------------------- */
    modifier onlyFileOwner(bytes32 fileId) {
        // requre msg.sender is owner of fileId
        require(
            files[fileId].fileOwner == msg.sender,
            "FileRegistry::onlyFileOwner: You do not have access."
        );
        _;
    }

    /* ------------------------------- CONSTRUCTOR ------------------------------ */
    constructor(MinimalForwarder forwarder)
        ERC2771Context(address(forwarder))
    {}

    /* -------------------------------------------------------------------------- */
    /*                                  FUNCTIONS                                 */
    /* -------------------------------------------------------------------------- */

    function registerFile(bytes32 fileId) public returns (bool fileRegistered) {
        require(
            files[fileId].fileOwner == address(0),
            "FileRegistry::registerFile: File already exists."
        );
        address msgSender = _msgSender();
        files[fileId].fileOwner = msgSender;
        files[fileId].accessRights[msgSender] = true;
        emit FileRegistered(fileId, msgSender);
        return true;
    }

    function grantAccess(bytes32 fileId, address recipient)
        public
        onlyFileOwner(fileId)
        returns (bool accessGranted)
    {
        require(
            !files[fileId].accessRights[recipient],
            "FileRegistry::grantAccess: Recipient is already granted."
        );
        files[fileId].accessRights[recipient] = true;
        emit AccessGranted(fileId, recipient);
        return true;
    }

    function revokeAccess(bytes32 fileId, address recipient)
        public
        onlyFileOwner(fileId)
        returns (bool accessRevoked)
    {
        require(
            files[fileId].accessRights[recipient],
            "FileRegistry::revokeAccess: No access is granted to this Recipient."
        );
        files[fileId].accessRights[recipient] = false;
        emit AccessRevoked(fileId, recipient);
        return true;
    }

    function hasAccess(bytes32 fileId, address recipient)
        public
        view
        returns (bool _hasAccess)
    {
        return files[fileId].accessRights[recipient];
    }
}
