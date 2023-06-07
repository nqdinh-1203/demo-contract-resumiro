// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IExperience {
    struct AppExperience {
        uint id;
        string position;
        string start;
        string finish;
        uint companyId;
        address owner;
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

    function deleteExperience(uint _id, address _user) external;

    function getExperience(
        uint _id
    ) external view returns (AppExperience memory);

    function getAllExperiences() external view returns (AppExperience[] memory);

    function getAllExperiencesOf(
        address _userAddress
    ) external view returns (AppExperience[] memory);
}
