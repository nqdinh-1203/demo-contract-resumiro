// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IUser.sol";

interface IResume {
    struct AppResume {
        uint id;
        string data;
        address owner;
        string title;
        uint createAt;
        // uint updateAt;
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
        string memory _data,
        address _candidateAddress,
        string memory _title,
        uint _createAt
    ) external;

    // function updateResume(
    //     uint _id,
    //     string memory _data,
    //     uint256 _updateAt
    // ) external;

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
    ) external view returns (address[] memory);

    function connectResumeRecruiter(
        address _recruiterAddress,
        uint _resumeId
    ) external;

    function disconnectResumeRecruiter(
        address _recruiterAddress,
        uint _resumeId
    ) external;
}
