// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IUser.sol";
import "./library/EnumrableSet.sol";
import "./abstract-contract/AccessControl.sol";

contract User is IUser, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    //=============================ATTRIBUTES==========================================
    EnumerableSet.AddressSet userAddresses;
    EnumerableSet.AddressSet candidateAddresses;
    EnumerableSet.AddressSet recruiterAddresses;
    EnumerableSet.AddressSet verifierAddresses;
    EnumerableSet.AddressSet adminRecruiterAddresses;

    mapping(address => AppUser) users;

    //=============================EVENTS==========================================
    event AddUser(address indexed user_address, UserType user_type);
    event DeleteUser(address indexed user_address, UserType user_type);

    //=============================ERRORS==========================================
    error AlreadyExistedUser(address user_address, UserType user_type);
    error NotExistedUser(address user_address);

    //=============================METHODS==========================================
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
    function _getAllVerifiers() internal view returns (address[] memory) {
        address[] memory arrUser = new address[](verifierAddresses.length());

        for (uint i = 0; i < verifierAddresses.length(); i++) {
            arrUser[i] = users[verifierAddresses.at(i)].accountAddress;
        }

        return arrUser;
    }

    // new ⭐ -> change AppUser[] to address[]
    function _getAllAdminRecruiters() internal view returns (address[] memory) {
        address[] memory arrUser = new address[](adminRecruiterAddresses.length());

        for (uint i = 0; i < adminRecruiterAddresses.length(); i++) {
            arrUser[i] = users[adminRecruiterAddresses.at(i)].accountAddress;
        }

        return arrUser;
    }

    // only admin -> later⏳ -> done✅
    // user must not existed -> done✅
    // user type just in enum UserType
    function _addUser(
        address _userAddress,
        uint _type
    ) internal onlyRole(ADMIN_ROLE) {
        bool existed = userAddresses.contains(_userAddress);
        if (existed) {
            revert AlreadyExistedUser({
                user_address: _userAddress,
                user_type: UserType(_type)
            });
        }

        users[_userAddress] = AppUser(_userAddress, UserType(_type));
        userAddresses.add(_userAddress);

        AppUser memory user = _getUser(_userAddress);

        if (_type == 0) {
            _setRole(_userAddress, CANDIDATE_ROLE);
            candidateAddresses.add(_userAddress);
        } 
        else if (_type == 1) {
            _setRole(_userAddress, RECRUITER_ROLE);
            recruiterAddresses.add(_userAddress);
        }
        else if (_type == 2) {
            _setRole(_userAddress, VERIFIER_ROLE);
            verifierAddresses.add(_userAddress);
        }
        else if (_type == 3) {
            _setRole(_userAddress, ADMIN_RECRUITER_ROLE);
            adminRecruiterAddresses.add(_userAddress);
        }

        emit AddUser(_userAddress, user.userType);
    }

    // only admin -> later⏳ -> done✅
    // user must existed -> done✅
    function _deleteUser(address _userAddress) internal onlyRole(ADMIN_ROLE) {
        bool existed = userAddresses.contains(_userAddress);
        if (!existed) {
            revert NotExistedUser({user_address: _userAddress});
        }

        AppUser memory deletedUser = _getUser(_userAddress);

        delete users[_userAddress];
        userAddresses.remove(_userAddress);

        if (_hasRole(_userAddress, CANDIDATE_ROLE)) {
            _revokeRole(_userAddress, CANDIDATE_ROLE);
            candidateAddresses.remove(_userAddress);
        } 
        else if (_hasRole(_userAddress, RECRUITER_ROLE)) {
            _revokeRole(_userAddress, RECRUITER_ROLE);
            recruiterAddresses.remove(_userAddress);
        }
        else if (_hasRole(_userAddress, VERIFIER_ROLE)) {
            _revokeRole(_userAddress, VERIFIER_ROLE);
            verifierAddresses.remove(_userAddress);
        }
        else if (_hasRole(_userAddress, ADMIN_RECRUITER_ROLE)) {
            _revokeRole(_userAddress, ADMIN_RECRUITER_ROLE);
            adminRecruiterAddresses.remove(_userAddress);
        }

        emit DeleteUser(_userAddress, deletedUser.userType);
    }

    //=============================FOR INTERFACE==========================================
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

    function getAllVerifiers() external view returns (address[] memory) {
        return _getAllVerifiers();
    }

    function getAllAdminRecruiters() external view returns (address[] memory) {
        return _getAllAdminRecruiters();
    }

    function addUser(address _userAddress, uint _type) external {
        _addUser(_userAddress, _type);
    }

    function deleteUser(address _userAddress) external {
        _deleteUser(_userAddress);
    }
}
