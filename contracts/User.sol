// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IUser.sol";
import "./library/EnumrableSet.sol";
import "./abstract-contract/AccessControl.sol";

contract User is IUser, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    //=============================[ATTRIBUTES]==========================================
    EnumerableSet.AddressSet userAddresses;
    EnumerableSet.AddressSet candidateAddresses;
    EnumerableSet.AddressSet recruiterAddresses;
    // EnumerableSet.AddressSet verifierAddresses;
    EnumerableSet.AddressSet adminRecruiterAddresses;

    mapping(address => AppUser) users;

    //=============================[EVENTS]==========================================
    event AddUser(address indexed user_address, UserType user_type);
    event DeleteUser(address indexed user_address, UserType user_type);

    //=============================[ERRORS]==========================================
    error User__AlreadyExisted(address user_address, UserType user_type);
    error User__NotExisted(address user_address);

    error User__NoType(uint user_type);
    error User__NotForSelf(address user_address, address origin_address);

    //===============================[METHODS]==========================================
    modifier onlySelf(address _account) {
        if (_account != tx.origin) {
            revert User__NotForSelf({
                user_address: _account,
                origin_address: tx.origin
            });
        }
        _;
    }

    constructor() {
        _setRole(msg.sender, ADMIN_ROLE);
    }

    function _getUser(
        address _userAddress
    ) internal view returns (AppUser memory) {
        return users[_userAddress];
    }

    function _getAllUser() internal view returns (AppUser[] memory) {
        AppUser[] memory arrUser = new AppUser[](userAddresses.length());

        for (uint i = 0; i < userAddresses.length(); i++) {
            arrUser[i] = users[userAddresses.at(i)];
        }

        return arrUser;
    }

    // new ⭐ -> change AppUser[] to address[]
    function _getAllCandidates() internal view returns (address[] memory) {
        address[] memory arrUser = new address[](candidateAddresses.length());

        for (uint i = 0; i < candidateAddresses.length(); i++) {
            arrUser[i] = users[candidateAddresses.at(i)].accountAddress;
        }

        return arrUser;
    }

    // new ⭐ -> change AppUser[] to address[]
    function _getAllRecruiters() internal view returns (address[] memory) {
        address[] memory arrUser = new address[](recruiterAddresses.length());

        for (uint i = 0; i < recruiterAddresses.length(); i++) {
            arrUser[i] = users[recruiterAddresses.at(i)].accountAddress;
        }

        return arrUser;
    }

    // new ⭐ -> change AppUser[] to address[]
    // function _getAllVerifiers() internal view returns (address[] memory) {
    //     address[] memory arrUser = new address[](verifierAddresses.length());

    //     for (uint i = 0; i < verifierAddresses.length(); i++) {
    //         arrUser[i] = users[verifierAddresses.at(i)].accountAddress;
    //     }

    //     return arrUser;
    // }

    // new ⭐ -> change AppUser[] to address[]
    function _getAllAdminCompany() internal view returns (address[] memory) {
        address[] memory arrUser = new address[](
            adminRecruiterAddresses.length()
        );

        for (uint i = 0; i < adminRecruiterAddresses.length(); i++) {
            arrUser[i] = users[adminRecruiterAddresses.at(i)].accountAddress;
        }

        return arrUser;
    }

    // only admin -> later⏳ -> done✅
    // user must not existed -> done✅
    // user type just in enum UserType -> done✅
    function _addUser(
        address _userAddress,
        uint _type
    ) internal onlySelf(_userAddress) {
        bool existed = userAddresses.contains(_userAddress);
        if (existed) {
            revert User__AlreadyExisted({
                user_address: _userAddress,
                user_type: users[_userAddress].userType
            });
        }

        if (_type >= 3) {
            revert User__NoType({user_type: _type});
        }

        users[_userAddress] = AppUser(_userAddress, UserType(_type));
        userAddresses.add(_userAddress);

        AppUser memory user = _getUser(_userAddress);

        if (_type == 0) {
            _setRole(_userAddress, CANDIDATE_ROLE);
            candidateAddresses.add(_userAddress);
        } else if (_type == 1) {
            _setRole(_userAddress, RECRUITER_ROLE);
            recruiterAddresses.add(_userAddress);
        } else if (_type == 2) {
            _setRole(_userAddress, ADMIN_COMPANY_ROLE);
            adminRecruiterAddresses.add(_userAddress);
        }

        emit AddUser(_userAddress, user.userType);
    }

    // only admin -> later⏳ -> done✅
    // user must existed -> done✅
    function _deleteUser(address _userAddress) internal onlyRole(ADMIN_ROLE) {
        bool existed = userAddresses.contains(_userAddress);
        if (!existed) {
            revert User__NotExisted({user_address: _userAddress});
        }

        AppUser memory deletedUser = _getUser(_userAddress);

        delete users[_userAddress];
        userAddresses.remove(_userAddress);

        if (_hasRole(_userAddress, CANDIDATE_ROLE)) {
            _revokeRole(_userAddress, CANDIDATE_ROLE);
            candidateAddresses.remove(_userAddress);
        } else if (_hasRole(_userAddress, RECRUITER_ROLE)) {
            _revokeRole(_userAddress, RECRUITER_ROLE);
            recruiterAddresses.remove(_userAddress);
        } else if (_hasRole(_userAddress, ADMIN_COMPANY_ROLE)) {
            _revokeRole(_userAddress, ADMIN_COMPANY_ROLE);
            adminRecruiterAddresses.remove(_userAddress);
        }

        emit DeleteUser(_userAddress, deletedUser.userType);
    }

    //=============================[FOR INTERFACE]==========================================
    function hasRole(
        address _account,
        bytes32 _role
    ) external view returns (bool) {
        return _hasRole(_account, _role);
    }

    // Gán role (update chỉ có admin/deployer mới đc gán)
    function grantRole(address _account, bytes32 _role) external {
        _grantRole(_account, _role);
    }

    function revokeRole(address _account, bytes32 _role) external {
        _revokeRole(_account, _role);
    }

    function isExisted(address _userAddress) external view returns (bool) {
        return userAddresses.contains(_userAddress);
    }

    function hasType(address _user, uint _type) external view returns (bool) {
        return users[_user].userType == UserType(_type);
    }

    function getUser(
        address _userAddress
    ) external view returns (AppUser memory) {
        return _getUser(_userAddress);
    }

    function getAllUser() external view returns (AppUser[] memory) {
        return _getAllUser();
    }

    function getAllCandidates() external view returns (address[] memory) {
        return _getAllCandidates();
    }

    function getAllRecruiters() external view returns (address[] memory) {
        return _getAllRecruiters();
    }

    // function getAllVerifiers() external view returns (address[] memory) {
    //     return _getAllVerifiers();
    // }

    function getAllAdminCompany() external view returns (address[] memory) {
        return _getAllAdminCompany();
    }

    function addUser(address _userAddress, uint _type) external {
        _addUser(_userAddress, _type);
    }

    function deleteUser(address _userAddress) external {
        _deleteUser(_userAddress);
    }
}
