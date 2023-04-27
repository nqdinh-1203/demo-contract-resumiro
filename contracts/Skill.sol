// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./library/UintArray.sol";
import "../interfaces/IUser.sol";
import "../interfaces/IJob.sol";
import "../interfaces/ISkill.sol";

contract Skill is ISkill {
    //=============================ATTRIBUTES==========================================
    uint[] allSkills;
    mapping(uint => AppSkill) skills;
    mapping(address => mapping(uint => bool)) skillsOfCandidate;
    mapping(uint => mapping(uint => bool)) skillsOfJob;
    IUser user;
    IJob job;

    constructor(address _userContract, address _jobContract) {
        user = IUser(_userContract);
        job = IJob(_jobContract);
    }

    //=============================EVENTS==========================================
    event AddSkill(uint id, string name);
    event DeleteSkill(uint id, string name);
    event ConnectCandidateSkill(
        address indexed candidate_address,
        uint[] skill_ids
    );
    event DisconnectCandidateSkill(
        address indexed candidate_address,
        uint[] skills_ids
    );
    event ConnectJobSkill(uint[] skill_ids, uint job_id);
    event DisconnectJobSkill(uint[] skills_ids, uint job_id);

    //=============================ERRORS==========================================
    error AlreadyExistedSkill(uint id, string name);
    error NotExistedSkill(uint id);

    error NotCandidate(address user_address);
    error NotConnectedSkillCandidate(uint skill_id, address candidate_address);
    error NotConnectedSkillJob(uint skill_id, uint job_id);

    error NotExistedJob(uint job_id);

    //=============================METHODS==========================================
    //====================SKILLS============================

    // skill id must not existed -> done✅
    function _addSkill(uint _id, string memory _name) internal {
        if (skills[_id].exist) {
            revert AlreadyExistedSkill({id: _id, name: _name});
        }
        skills[_id] = AppSkill(allSkills.length, _id, _name, true);
        allSkills.push(_id);

        emit AddSkill(_id, _name);
    }

    // skill id must existed -> done✅
    function _deleteSkill(uint _id) internal {
        if (!skills[_id].exist) {
            revert NotExistedSkill({id: _id});
        }

        AppSkill memory skill = skills[_id];

        skills[allSkills[allSkills.length - 1]].index = skills[_id].index;
        UintArray.remove(allSkills, skills[_id].index);

        delete skills[_id];

        emit DeleteSkill(_id, skill.name);
    }

    function _getAllSkill() internal view returns (AppSkill[] memory) {
        AppSkill[] memory arrSkill = new AppSkill[](allSkills.length);

        for (uint i = 0; i < allSkills.length; i++) {
            arrSkill[i] = skills[allSkills[i]];
        }

        return arrSkill;
    }

    //====================SKILL-CANDIDATE============================
    // only candidate -> later⏳
    // param _candidate must equal msg.sender -> later⏳
    // skill must existed -> done✅
    // just connect with candidate -> done✅
    // continue connected skill -> done✅
    function _connectCandidateSkill(
        address _candidate,
        uint[] memory _skills
    ) internal {
        if (!(user.isExisted(_candidate) && user.hasType(_candidate, 0))) {
            revert NotCandidate({user_address: _candidate});
        }

        for (uint i = 0; i < _skills.length; i++) {
            if (!skills[_skills[i]].exist) {
                revert NotExistedSkill({id: _skills[i]});
            }
        }
        for (uint i = 0; i < _skills.length; i++) {
            if (skillsOfCandidate[_candidate][_skills[i]]) {
                continue;
            } else {
                skillsOfCandidate[_candidate][_skills[i]] = true;
            }
        }

        emit ConnectCandidateSkill(_candidate, _skills);
    }

    // only candidate -> later⏳
    // param _candidate must equal msg.sender -> later⏳
    // skill must existed -> done✅
    // just connect with candidate -> done✅
    // must not have not connected skill-candidate -> done✅
    function _disconnectCandidateSkill(
        address _candidate,
        uint[] memory _skills
    ) internal {
        if (!(user.isExisted(_candidate) && user.hasType(_candidate, 0))) {
            revert NotCandidate({user_address: _candidate});
        }
        for (uint i = 0; i < _skills.length; i++) {
            if (!skills[_skills[i]].exist) {
                revert NotExistedSkill({id: _skills[i]});
            }
            if (!skillsOfCandidate[_candidate][_skills[i]]) {
                revert NotConnectedSkillCandidate({
                    skill_id: _skills[i],
                    candidate_address: _candidate
                });
            }
        }

        for (uint i = 0; i < _skills.length; i++) {
            skillsOfCandidate[_candidate][_skills[i]] = false;
        }

        emit DisconnectCandidateSkill(_candidate, _skills);
    }

    function _getAllSkillsOfCandidate(
        address _candidate
    ) internal view returns (AppSkill[] memory) {
        AppSkill[] memory arrSkill = new AppSkill[](allSkills.length);

        for (uint i = 0; i < allSkills.length; i++) {
            if (skillsOfCandidate[_candidate][allSkills[i]]) {
                arrSkill[i] = skills[i];
            }
        }

        return arrSkill;
    }

    //====================SKILL-JOB============================
    // only recruiter -> later⏳
    // skill must existed -> done✅
    // job must existed
    // continue connected skill -> done✅
    function _connectJobSkill(uint[] memory _skills, uint _job) internal {
        for (uint i = 0; i < _skills.length; i++) {
            if (!skills[_skills[i]].exist) {
                revert NotExistedSkill({id: _skills[i]});
            }
        }

        if (!job.isExistedJob(_job)) {
            revert NotExistedJob({job_id: _job});
        }

        for (uint i = 0; i < _skills.length; i++) {
            if (skillsOfJob[_job][_skills[i]]) {
                continue;
            } else {
                skillsOfJob[_job][_skills[i]] = true;
            }
        }

        emit ConnectJobSkill(_skills, _job);
    }

    // only recruiter -> later⏳
    // param _candidate must equal msg.sender -> later⏳
    // skill must existed -> done✅
    // must not have not connected skill-job -> done✅
    function _disconnectJobSkill(uint[] memory _skills, uint _job) internal {
        if (!job.isExistedJob(_job)) {
            revert NotExistedJob({job_id: _job});
        }

        for (uint i = 0; i < _skills.length; i++) {
            if (!skills[_skills[i]].exist) {
                revert NotExistedSkill({id: _skills[i]});
            }
            if (!skillsOfJob[_job][_skills[i]]) {
                revert NotConnectedSkillJob({
                    skill_id: _skills[i],
                    job_id: _job
                });
            }
        }

        for (uint i = 0; i < _skills.length; i++) {
            skillsOfJob[_job][_skills[i]] = false;
        }

        emit DisconnectJobSkill(_skills, _job);
    }

    function _getAllSkillsOfJob(
        uint _jobId
    ) internal view returns (AppSkill[] memory) {
        AppSkill[] memory arrSkill = new AppSkill[](allSkills.length);

        for (uint i = 0; i < allSkills.length; i++) {
            if (skillsOfJob[_jobId][allSkills[i]]) {
                arrSkill[i] = skills[i];
            }
        }

        return arrSkill;
    }

    //======================FOR INTERFACE==========================
    function addSkill(uint _id, string memory _name) external {
        _addSkill(_id, _name);
    }

    function deleteSkill(uint _id) external {
        _deleteSkill(_id);
    }

    function getAllSkill() external view returns (AppSkill[] memory) {
        return _getAllSkill();
    }

    function connectCandidateSkill(
        address _candidate,
        uint[] memory _skills
    ) external {
        _connectCandidateSkill(_candidate, _skills);
    }

    function disconnectCandidateSkill(
        address _candidate,
        uint[] memory _skills
    ) external {
        _disconnectCandidateSkill(_candidate, _skills);
    }

    function getAllSkillsOfCandidate(
        address _candidate
    ) external view returns (AppSkill[] memory) {
        return _getAllSkillsOfCandidate(_candidate);
    }

    function connectJobSkill(uint[] memory _skills, uint _job) external {
        _connectJobSkill(_skills, _job);
    }

    function disconnectJobSkill(uint[] memory _skills, uint _job) external {
        _disconnectJobSkill(_skills, _job);
    }

    function getAllSkillsOfJob(
        uint _jobId
    ) external view returns (AppSkill[] memory) {
        return _getAllSkillsOfJob(_jobId);
    }

    //======================USER CONTRACT==========================
    function setUserInterface(address _contract) public {
        user = IUser(_contract);
    }

    function setJobInterface(address _contract) public {
        job = IJob(_contract);
    }
}
