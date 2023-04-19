// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract User {
    enum UserType {
        RECRUITER,
        CANDIDATE
    }

    struct AppUser {
        UserType userType;
        bool exist;
    }

    mapping(address => AppUser) users;

    event AddUser(address indexed user_address, UserType user_type, bool exist);
    event DeleteUser(address indexed user_address, UserType user_type);

    function getUser(
        address _userAddress
    ) public view returns (AppUser memory) {
        return users[_userAddress];
    }

    function addUser(address _userAddress, uint _type) public virtual {
        require(!users[_userAddress].exist, "User: address already existed");
        users[_userAddress] = AppUser(UserType(_type), true);

        AppUser memory user = getUser(_userAddress);

        emit AddUser(_userAddress, user.userType, user.exist);
    }

    function deleteUser(address _userAddress) public virtual {
        require(users[_userAddress].exist, "User: address not existed");
        AppUser memory deletedUser = getUser(_userAddress);

        delete users[_userAddress];

        emit DeleteUser(_userAddress, deletedUser.userType);
    }
}
