// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IExperience {
    struct AppExperience {
        uint index;
        uint id;
        string position;
        uint start;
        uint finish;
        uint companyId;
        bool exist;
        address owner;
    }

    function addExperience(
        address _user,
        uint _id,
        string memory _position,
        uint _start,
        uint _finish,
        uint _companyId
    ) external;

    function updateExperience(
        address _user,
        uint _id,
        string memory _position,
        uint _start,
        uint _finish,
        uint _companyId
    ) external;

    function deleteExperience(address _user, uint _id) external;

    function getExperience(
        uint _id
    ) external view returns (AppExperience memory);

    function getAllExperiences() external view returns (AppExperience[] memory);

    function getAllExperiencesOf(
        address _userAddress
    ) external view returns (AppExperience[] memory);
}
