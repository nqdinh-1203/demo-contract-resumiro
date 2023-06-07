// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IUser {
    enum UserType {
        CANDIDATE,
        RECRUITER,
        ADMIN
    }

    struct AppUser {
        address accountAddress;
        UserType userType;
    }

    function hasRole(
        address _account,
        bytes32 _role
    ) external view returns (bool);

    function grantRole(address _account, bytes32 _role) external;

    function revokeRole(address _account, bytes32 _role) external;

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
