// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IUser.sol";
import "../interfaces/IJob.sol";
import "../interfaces/ISkill.sol";
import "./library/EnumrableSet.sol";

contract Skill is ISkill {
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant CANDIDATE_ROLE = keccak256("CANDIDATE_ROLE");
    bytes32 public constant RECRUITER_ROLE = keccak256("RECRUITER_ROLE");
    bytes32 public constant ADMIN_COMPANY_ROLE =
        keccak256("ADMIN_COMPANY_ROLE");

    //=============================ATTRIBUTES==========================================
    EnumerableSet.UintSet skillIds;
    uint skillCounter = 1;
    mapping(uint => AppSkill) skills;
    mapping(address => EnumerableSet.UintSet) skillsOfCandidate;
    mapping(uint => EnumerableSet.UintSet) skillsOfJob;

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
    error User__NoRole(address account);
    error User__NotPermit(address account);

    error Skill__AlreadyExisted(uint id, string name);
    error Skill__NotExisted(uint id);

    error Candidate__NotExisted(address user_address);

    error Skill_Candidate__NotConnected(
        uint skill_id,
        address candidate_address
    );
    error Skill_Candidate__NotForSelf(
        address candidate_address,
        address origin_address
    );
    error Skill_Job__NotConnected(uint skill_id, uint job_id);

    error NotExistedJob(uint job_id);
    error Caller_Job__NotOwn(uint job_id, address caller);

    //=============================METHODS==========================================
    modifier onlyRole(bytes32 _role) {
        if (!user.hasRole(tx.origin, _role)) {
            revert User__NoRole({account: tx.origin});
        }
        _;
    }

    modifier onlyRecruiterAndAdminCom() {
        if (
            !(user.hasRole(tx.origin, RECRUITER_ROLE) &&
                user.hasRole(tx.origin, ADMIN_COMPANY_ROLE))
        ) {
            revert User__NotPermit({account: tx.origin});
        }
        _;
    }

    modifier onlySelf(address _account) {
        if (_account != tx.origin) {
            revert Skill_Candidate__NotForSelf({
                candidate_address: _account,
                origin_address: tx.origin
            });
        }
        _;
    }

    modifier onlyOwnJob(uint _jobId) {
        IJob.AppJob memory j = job.getJob(_jobId);
        if (j.owner != tx.origin) {
            revert Caller_Job__NotOwn({job_id: _jobId, caller: tx.origin});
        }
        _;
    }

    //====================SKILLS============================
    // skill id must not existed -> done✅
    function _addSkill(string memory _name) internal {
        uint _id = skillCounter;
        skillCounter++;

        skills[_id] = AppSkill(_id, _name);
        skillIds.add(_id);

        emit AddSkill(_id, _name);
    }

    // skill id must existed -> done✅
    function _deleteSkill(uint _id) internal {
        if (!skillIds.contains(_id)) {
            revert Skill__NotExisted({id: _id});
        }

        AppSkill memory skill = skills[_id];

        skillIds.remove(_id);
        delete skills[_id];

        emit DeleteSkill(_id, skill.name);
    }

    function _getAllSkill() internal view returns (AppSkill[] memory) {
        AppSkill[] memory skillArr = new AppSkill[](skillIds.length());

        for (uint i = 0; i < skillIds.length(); i++) {
            skillArr[i] = skills[skillIds.at(i)];
        }

        return skillArr;
    }

    //====================SKILL-CANDIDATE============================
    // only candidate -> later⏳ -> done✅
    // param _candidate must equal msg.sender -> later⏳-> done✅
    // skill must existed -> done✅
    // just connect with candidate -> done✅
    // continue connected skill -> done✅
    function _connectCandidateSkill(
        address _candidate,
        uint[] memory _skills
    ) internal onlyRole(CANDIDATE_ROLE) onlySelf(_candidate) {
        if (!(user.isExisted(_candidate) && user.hasType(_candidate, 0))) {
            revert Candidate__NotExisted({user_address: _candidate});
        }

        for (uint i = 0; i < _skills.length; i++) {
            if (!skillIds.contains(_skills[i])) {
                revert Skill__NotExisted({id: _skills[i]});
            }
        }
        for (uint i = 0; i < _skills.length; i++) {
            if (!skillsOfCandidate[_candidate].contains(_skills[i])) {
                skillsOfCandidate[_candidate].add(_skills[i]);
            }
        }

        emit ConnectCandidateSkill(_candidate, _skills);
    }

    // only candidate -> later⏳ -> done✅
    // param _candidate must equal msg.sender -> later⏳ -> done✅
    // skill must existed -> done✅
    // just connect with candidate -> done✅
    // must not have not connected skill-candidate -> done✅
    function _disconnectCandidateSkill(
        address _candidate,
        uint[] memory _skills
    ) internal onlyRole(CANDIDATE_ROLE) onlySelf(_candidate) {
        if (!(user.isExisted(_candidate) && user.hasType(_candidate, 0))) {
            revert Candidate__NotExisted({user_address: _candidate});
        }
        for (uint i = 0; i < _skills.length; i++) {
            if (!skillIds.contains(_skills[i])) {
                revert Skill__NotExisted({id: _skills[i]});
            }
            if (!skillsOfCandidate[_candidate].contains(_skills[i])) {
                revert Skill_Candidate__NotConnected({
                    skill_id: _skills[i],
                    candidate_address: _candidate
                });
            }
        }

        for (uint i = 0; i < _skills.length; i++) {
            skillsOfCandidate[_candidate].add(_skills[i]);
        }

        emit DisconnectCandidateSkill(_candidate, _skills);
    }

    function _getAllSkillsOfCandidate(
        address _candidate
    ) internal view returns (AppSkill[] memory) {
        AppSkill[] memory skillArr = new AppSkill[](
            skillsOfCandidate[_candidate].length()
        );

        for (uint i = 0; i < skillsOfCandidate[_candidate].length(); i++) {
            skillArr[i] = skills[skillsOfCandidate[_candidate].at(i)];
        }

        return skillArr;
    }

    //====================SKILL-JOB============================
    // only recruiter -> later⏳ -> done✅
    // skill must existed -> done✅
    // job must existed
    // continue connected skill -> done✅
    function _connectJobSkill(
        uint[] memory _skills,
        uint _job
    ) internal onlyRecruiterAndAdminCom onlyOwnJob(_job) {
        _disconnectAllJobSkill(_job);
        for (uint i = 0; i < _skills.length; i++) {
            if (!skillIds.contains(_skills[i])) {
                revert Skill__NotExisted({id: _skills[i]});
            }
        }
        if (!job.isExistedJob(_job)) {
            revert NotExistedJob({job_id: _job});
        }

        for (uint i = 0; i < _skills.length; i++) {
            if (skillsOfJob[_job].contains(_skills[i])) {
                skillsOfJob[_job].add(_skills[i]);
            }
        }

        emit ConnectJobSkill(_skills, _job);
    }

    function _disconnectAllJobSkill(
        uint _job
    ) internal onlyRecruiterAndAdminCom onlyOwnJob(_job) {
        for (uint i = 0; i < skillIds.length(); i++) {
            if (skillsOfJob[_job].contains(skillIds.at(i))) {
                skillsOfJob[_job].remove(skillIds.at(i));
            }
        }
    }

    // only recruiter -> later⏳ -> done✅
    // skill must existed -> done✅
    // must not have not connected skill-job -> done✅
    function _disconnectJobSkill(
        uint[] memory _skills,
        uint _job
    ) internal onlyRecruiterAndAdminCom onlyOwnJob(_job) {
        if (!job.isExistedJob(_job)) {
            revert NotExistedJob({job_id: _job});
        }

        for (uint i = 0; i < _skills.length; i++) {
            if (!skillIds.contains(_skills[i])) {
                revert Skill__NotExisted({id: _skills[i]});
            }
            if (!skillsOfJob[_job].contains(_skills[i])) {
                revert Skill_Job__NotConnected({
                    skill_id: _skills[i],
                    job_id: _job
                });
            }
        }

        for (uint i = 0; i < _skills.length; i++) {
            skillsOfJob[_job].remove(_skills[i]);
        }

        emit DisconnectJobSkill(_skills, _job);
    }

    function _getAllSkillsOfJob(
        uint _jobId
    ) internal view returns (AppSkill[] memory) {
        uint length = skillsOfJob[_jobId].length();
        AppSkill[] memory skillArr = new AppSkill[](length);

        for (uint i = 0; i < length; i++) {
            skillArr[i] = skills[skillsOfJob[_jobId].at(i)];
        }

        return skillArr;
    }

    //======================FOR INTERFACE==========================
    function addSkill(string memory _name) external {
        _addSkill(_name);
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
