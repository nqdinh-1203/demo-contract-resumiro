// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IUser.sol";

interface IJob {
    struct AppJob {
        uint index;
        uint id;
        string title;
        string location;
        string jobType;
        uint createAt;
        uint updateAt;
        uint companyId;
        uint salary;
        string field;
        bool exist;
        address owner;
    }

    function isExistedJob(uint _jobId) external view returns (bool);

    function isOwnerOfJob(
        address _recruiterAddress,
        uint _jobId
    ) external view returns (bool);

    function getJob(uint _id) external view returns (AppJob memory);

    function getAllJobs() external view returns (AppJob[] memory);

    function getAllJobsOf(
        address _recruiterAddress
    ) external view returns (AppJob[] memory);

    function addJob(
        uint _id,
        string memory _title,
        string memory _location,
        string memory _jobType,
        uint _createAt,
        uint _companyId,
        uint _salary,
        string memory _field,
        address _recruiterAddress
    ) external;

    function updateJob(
        uint _id,
        string memory _title,
        string memory _location,
        string memory _jobType,
        uint _updateAt,
        uint _companyId,
        uint _salary,
        string memory _field
    ) external;

    function deleteJob(uint _id) external;

    function connectJobCandidate(
        address _candidateAddress,
        uint _jobId
    ) external;

    function disconnectJobCandidate(
        address _candidateAddress,
        uint _jobId
    ) external;

    function getAllAppliedJobsOf(
        address _candidate
    ) external view returns (AppJob[] memory);

    function getAllAppliedCandidatesOf(
        uint _jobId
    ) external view returns (IUser.AppUser[] memory);
}
