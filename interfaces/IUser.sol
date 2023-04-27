// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IUser {
    enum UserType {
        CANDIDATE,
        RECRUITER
    }

    struct AppUser {
        uint index;
        UserType userType;
        bool exist;
        address accountAddress;
    }

    function isExisted(address _userAddress) external view returns (bool);

    function hasType(address _user, uint _type) external view returns (bool);

    function getUser(
        address _userAddress
    ) external view returns (AppUser memory);

    function getAllUser() external view returns (AppUser[] memory);

    function getAllCandidates() external view returns (AppUser[] memory);

    function getAllRecruiters() external view returns (AppUser[] memory);

    function addUser(address _userAddress, uint _type) external;

    function deleteUser(address _userAddress) external;
}
