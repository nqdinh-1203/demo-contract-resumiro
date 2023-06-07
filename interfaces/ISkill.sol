// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IUser.sol";

interface ISkill {
    struct AppSkill {
        uint id;
        string name;
    }

    function addSkill(string memory _name) external;

    function deleteSkill(uint _id) external;

    function getAllSkill() external view returns (AppSkill[] memory);

    function connectCandidateSkill(
        address _candidate,
        uint[] memory _skills
    ) external;

    function disconnectCandidateSkill(
        address _candidate,
        uint[] memory _skills
    ) external;

    function getAllSkillsOfCandidate(
        address _candidate
    ) external view returns (AppSkill[] memory);

    function connectJobSkill(uint[] memory _skills, uint _job) external;

    function disconnectJobSkill(uint[] memory _skills, uint _job) external;

    function getAllSkillsOfJob(
        uint _jobId
    ) external view returns (AppSkill[] memory);
}
