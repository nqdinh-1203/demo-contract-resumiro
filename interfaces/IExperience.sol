// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IExperience {
    // new ⭐ -> add status and verified_at
    struct AppExperience {
        uint id;
        string position;
        string start;
        string finish;
        uint companyId;
        ExpStatus status; // new 
        uint verifiedAt; // new
        address owner;
    }

    enum ExpStatus {
        Pending,
        Verified,
        Rejected
    }

    function addExperience(
        string memory _position,
        string memory _start,
        string memory _finish,
        uint _companyId,
        address _user
    ) external;

    function updateExperience(
        uint _id,
        string memory _position,
        string memory _start,
        string memory _finish,
        uint _companyId,
        address _user
    ) external;

    function changeExpStatus(uint _id, uint _status, uint _verifiedAt) external;

    function deleteExperience(uint _id, address _user) external;

    function getExperience(
        uint _id
    ) external view returns (AppExperience memory);

    function getAllExperiences() external view returns (AppExperience[] memory);

    function getAllExperiencesOf(
        address _userAddress
    ) external view returns (AppExperience[] memory);
}
