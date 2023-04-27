// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IUser.sol";

contract User is IUser {
    //=============================ATTRIBUTES==========================================
    address[] allUsers;
    mapping(address => AppUser) users;

    //=============================EVENTS==========================================
    event AddUser(address indexed user_address, UserType user_type, bool exist);
    event DeleteUser(address indexed user_address, UserType user_type);

    //=============================ERRORS==========================================
    error AlreadyExistedUser(address user_address, UserType user_type);
    error NotExistedUser(address user_address);

    //=============================METHODS==========================================
    function _getUser(
        address _userAddress
    ) internal view returns (AppUser memory) {
        return users[_userAddress];
    }

    function _getAllUser() internal view returns (AppUser[] memory) {
        AppUser[] memory arrUser = new AppUser[](allUsers.length);

        for (uint i = 0; i < allUsers.length; i++) {
            arrUser[i] = users[allUsers[i]];
        }

        return arrUser;
    }

    function _getAllCandidates() internal view returns (AppUser[] memory) {
        AppUser[] memory arrUser = new AppUser[](allUsers.length);

        for (uint i = 0; i < allUsers.length; i++) {
            if (users[allUsers[i]].userType == UserType(0)) {
                arrUser[i] = users[allUsers[i]];
            }
        }

        return arrUser;
    }

    function _getAllRecruiters() internal view returns (AppUser[] memory) {
        AppUser[] memory arrUser = new AppUser[](allUsers.length);

        for (uint i = 0; i < allUsers.length; i++) {
            if (users[allUsers[i]].userType == UserType(1)) {
                arrUser[i] = users[allUsers[i]];
            }
        }

        return arrUser;
    }

    // only admin -> later⏳
    // user must not existed -> done✅
    // user type just in enum UserType
    function _addUser(address _userAddress, uint _type) internal {
        if (users[_userAddress].exist) {
            revert AlreadyExistedUser({
                user_address: _userAddress,
                user_type: UserType(_type)
            });
        }

        users[_userAddress] = AppUser(
            allUsers.length,
            UserType(_type),
            true,
            _userAddress
        );
        allUsers.push(_userAddress);

        AppUser memory user = _getUser(_userAddress);

        emit AddUser(_userAddress, user.userType, user.exist);
    }

    // only admin -> later⏳
    // user must existed -> done✅
    function _deleteUser(address _userAddress) internal {
        if (!users[_userAddress].exist) {
            revert NotExistedUser({user_address: _userAddress});
        }

        AppUser memory deletedUser = _getUser(_userAddress);

        // swap to delete at allUsers list
        uint256 lastAddressIndex = allUsers.length - 1;
        users[allUsers[lastAddressIndex]].index = users[_userAddress].index;
        address temp = allUsers[users[_userAddress].index];
        allUsers[users[_userAddress].index] = allUsers[lastAddressIndex];
        allUsers[lastAddressIndex] = temp;
        allUsers.pop();

        delete users[_userAddress];

        emit DeleteUser(_userAddress, deletedUser.userType);
    }

    //=============================FOR INTERFACE==========================================
    function isExisted(address _userAddress) external view returns (bool) {
        return users[_userAddress].exist;
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

    function getAllCandidates() external view returns (AppUser[] memory) {
        return _getAllCandidates();
    }

    function getAllRecruiters() external view returns (AppUser[] memory) {
        return _getAllRecruiters();
    }

    function addUser(address _userAddress, uint _type) external {
        _addUser(_userAddress, _type);
    }

    function deleteUser(address _userAddress) external {
        _deleteUser(_userAddress);
    }
}
