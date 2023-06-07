// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

abstract contract AccessControl {
    bytes32 public constant ADMIN_ROLE = 0x00;
    bytes32 public constant CANDIDATE_ROLE = keccak256("CANDIDATE_ROLE");
    bytes32 public constant RECRUITER_ROLE = keccak256("RECRUITER_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant ADMIN_RECRUITER_ROLE = keccak256("ADMIN_RECRUITER_ROLE");

    //============================ERRORs================================
    error User__NoRole(address account);
    error User__ExistedRole(address account);

    //============================METHODS================================
    // địa chỉ ví của user có role k?
    struct RoleData {
        mapping(address => bool) users;
        // bytes32 adminRole;
    }

    event RoleGranted(address indexed account, bytes32 indexed role);
    // address indexed sender

    event RoleRevoked(address indexed account, bytes32 indexed role);
    // address indexed sender

    // Ứng với mỗi role có chứa address không?
    mapping(bytes32 => RoleData) private roles;

    function _hasRole(
        address _account,
        bytes32 _role
    ) internal view virtual returns (bool) {
        return roles[_role].users[_account];
    }

    modifier onlyRole(bytes32 _role) {
        if (!_hasRole(tx.origin, _role)) {
            revert User__NoRole({account: tx.origin});
        }
        _;
    }

    function _grantRole(
        address _account,
        bytes32 _role
    ) internal onlyRole(ADMIN_ROLE) {
        if (_hasRole(_account, _role)) {
            revert User__ExistedRole({account: _account});
        }

        roles[_role].users[_account] = true;
        emit RoleGranted(_account, _role);
    }

    function _revokeRole(
        address _account,
        bytes32 _role
    ) internal onlyRole(ADMIN_ROLE) {
        if (!_hasRole(_account, _role)) {
            revert User__NoRole({account: _account});
        }
        roles[_role].users[_account] = false;
        emit RoleRevoked(_account, _role);
    }

    function _setRole(address _account, bytes32 _role) internal {
        roles[_role].users[_account] = true;
        emit RoleGranted(_account, _role);
    }
}
