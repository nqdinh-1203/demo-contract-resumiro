// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IUser.sol";

interface IResume {
    struct AppResume {
        uint index;
        uint id;
        string data;
        uint createAt;
        uint updateAt;
        bool exist;
        address owner;
    }

    function isOwnerOfResume(
        address _candidateAddress,
        uint _id
    ) external view returns (bool);

    function getResume(uint _id) external view returns (AppResume memory);

    function getAllResumes() external view returns (AppResume[] memory);

    function getAllResumesOf(
        address _candidateAddress
    ) external view returns (AppResume[] memory);

    function addResume(
        uint _id,
        string memory _data,
        uint _createAt,
        address _candidateAddress
    ) external;

    function updateResume(
        uint _id,
        string memory _data,
        uint256 _updateAt
    ) external;

    function deleteResume(uint _id) external;

    function isExistedResumeRecruiter(
        address _recruiterAddress,
        uint _resumeId
    ) external view returns (bool);

    function getAllApprovedResumesOf(
        address _recruiterAddress
    ) external view returns (AppResume[] memory);

    function getAllApprovedRecruitersOf(
        uint _resumeId
    ) external view returns (IUser.AppUser[] memory);

    function connectResumeRecruiter(
        address _recruiterAddress,
        uint _resumeId
    ) external;

    function disconnectResumeRecruiter(
        address _recruiterAddress,
        uint _resumeId
    ) external;
}
