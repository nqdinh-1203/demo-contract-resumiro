// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

abstract contract AccessControl {
    bytes32 public constant ADMIN_ROLE = 0x00;
    bytes32 public constant CANDIDATE_ROLE = keccak256("CANDIDATE_ROLE");
    bytes32 public constant RECRUITER_ROLE = keccak256("RECRUITER_ROLE");

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

    function hasRole(
        address _account,
        bytes32 _role
    ) public view virtual returns (bool) {
        return roles[_role].users[_account];
    }

    modifier onlyRole(bytes32 _role) {
        require(hasRole(msg.sender, _role), "Role: Caller not have role");
        _;
    }

    function _grantRole(address _account, bytes32 _role) internal {
        roles[_role].users[_account] = true;
        emit RoleGranted(_account, _role);
    }

    // Gán role (update chỉ có admin/deployer mới đc gán)
    function grantRole(
        address _account,
        bytes32 _role
    ) public onlyRole(ADMIN_ROLE) {
        require(
            !hasRole(_account, _role),
            "Account have had this role to grant"
        );
        _grantRole(_account, _role);
    }

    function _revokeRole(address _account, bytes32 _role) public {
        roles[_role].users[_account] = false;
        emit RoleRevoked(_account, _role);
    }

    function revokeRole(
        address _account,
        bytes32 _role
    ) public onlyRole(ADMIN_ROLE) {
        require(
            hasRole(_account, _role),
            "Account have not had this role to revoke"
        );
        _revokeRole(_account, _role);
    }

    function _setRole(address _account, bytes32 _role) internal {
        _grantRole(_account, _role);
    }
}
