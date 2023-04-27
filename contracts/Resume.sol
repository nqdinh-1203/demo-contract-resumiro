// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IUser.sol";
import "../interfaces/IResume.sol";
import "./library/UintArray.sol";

// import "./abstract-contract/AccessControl.sol";

contract Resume is IResume {
    //=============================ATTRIBUTES==========================================
    uint[] allResumes;
    mapping(uint => AppResume) public resumes;
    mapping(address => mapping(uint => bool)) public resumeApprovals;
    mapping(uint => address) public candidateOwnResume;
    IUser public user;

    constructor(address _contract) {
        user = IUser(_contract);
    }

    //=============================EVENTS==========================================
    event AddResume(
        uint id,
        string data,
        uint create_at,
        uint update_at,
        address indexed owner_address
    );
    event DeleteResume(
        uint id,
        string data,
        uint create_at,
        uint update_at,
        address indexed owner_address
    );
    event UpdateResume(
        uint id,
        string data,
        uint create_at,
        uint update_at,
        address indexed owner_address
    );
    event Approval(
        address candidate_address,
        address recruiter_address,
        uint resume_id,
        bool isApproved
    );

    //=============================ERRORS==========================================
    error Resume__NotExisted(uint id);
    error Resume__AlreadyExisted(uint id);

    error Candidate_Resume__NotOwned(address candidate_address, uint id);

    error Recruiter__NotExisted(address user_address);
    error Candidate__NotExisted(address user_address);

    error Recruiter_Resume__NotApproved(address recruiter_address, uint id);
    error Recruiter_Resume__AlreadyApproved(address recruiter_address, uint id);

    //=============================METHODS==========================================

    //======================RESUMES==========================
    function _isOwnerOfResume(
        address _candidateAddress,
        uint _id
    ) internal view returns (bool) {
        return candidateOwnResume[_id] == _candidateAddress;
    }

    function _getResume(uint _id) internal view returns (AppResume memory) {
        return resumes[_id];
    }

    function _getAllResumes() internal view returns (AppResume[] memory) {
        AppResume[] memory arrResume = new AppResume[](allResumes.length);

        for (uint i = 0; i < arrResume.length; i++) {
            arrResume[i] = resumes[allResumes[i]];
        }

        return arrResume;
    }

    function _getAllResumesOf(
        address _candidateAddress
    ) internal view returns (AppResume[] memory) {
        AppResume[] memory arrResume = new AppResume[](allResumes.length);

        for (uint i = 0; i < arrResume.length; i++) {
            if (candidateOwnResume[allResumes[i]] == _candidateAddress) {
                arrResume[i] = resumes[allResumes[i]];
            }
        }

        return arrResume;
    }

    // only candidate -> later⏳
    // param _candidateAddress must equal msg.sender -> later⏳
    // resume must not existed -> done✅
    // just add for candidate -> done✅
    function _addResume(
        uint _id,
        string memory _data,
        uint _createAt,
        address _candidateAddress
    ) internal {
        if (resumes[_id].exist) {
            revert Resume__AlreadyExisted({id: _id});
        }
        if (
            !(user.isExisted(_candidateAddress) &&
                user.hasType(_candidateAddress, 0))
        ) {
            revert Candidate__NotExisted({user_address: _candidateAddress});
        }

        resumes[_id] = AppResume(
            allResumes.length,
            _id,
            _data,
            _createAt,
            _createAt,
            true,
            _candidateAddress
        );

        candidateOwnResume[_id] = _candidateAddress;
        allResumes.push(_id);

        AppResume memory resume = _getResume(_id);
        address owner = candidateOwnResume[_id];

        emit AddResume(
            _id,
            resume.data,
            resume.createAt,
            resume.updateAt,
            owner
        );
    }

    // only candidate -> later⏳
    // resume must existed -> done✅
    // caller must own resume -> later⏳
    // caller must be candidate in user contract -> later⏳
    function _updateResume(
        uint _id,
        string memory _data,
        uint256 _updateAt
    ) internal {
        if (!resumes[_id].exist) {
            revert Resume__NotExisted({id: _id});
        }
        // if (isOwnerOfResume(msg.sender, _id)) {
        //     revert Candidate_Resume__NotOwned({id: _id, candidate_address: msg.sender});
        // }

        resumes[_id].data = _data;
        resumes[_id].updateAt = _updateAt;

        AppResume memory resume = _getResume(_id);
        address owner = candidateOwnResume[_id];

        emit UpdateResume(
            _id,
            resume.data,
            resume.createAt,
            resume.updateAt,
            owner
        );
    }

    // only candidate -> later⏳
    // resume must existed -> done✅
    // caller must own resume -> later⏳
    // caller must be candidate in user contract -> later⏳
    function _deleteResume(uint _id) internal {
        if (!resumes[_id].exist) {
            revert Resume__NotExisted({id: _id});
        }

        // if (isOwnerOfResume(msg.sender, _id)) {
        //     revert Candidate_Resume__NotOwned({id: _id, candidate_address: msg.sender});
        // }

        AppResume memory resume = _getResume(_id);
        address ownerAddress = candidateOwnResume[_id];

        uint lastIndex = allResumes.length - 1;
        resumes[allResumes[lastIndex]].index = resumes[_id].index;
        UintArray.remove(allResumes, resumes[_id].index);

        delete resumes[_id];

        emit DeleteResume(
            _id,
            resume.data,
            resume.createAt,
            resume.updateAt,
            ownerAddress
        );
    }

    //======================RESUME-RECRUITER==========================
    function _isExistedResumeRecruiter(
        address _recruiterAddress,
        uint _resumeId
    ) internal view returns (bool) {
        return resumeApprovals[_recruiterAddress][_resumeId];
    }

    function _getAllApprovedResumesOf(
        address _recruiterAddress
    ) internal view returns (AppResume[] memory) {
        AppResume[] memory arrResume = new AppResume[](allResumes.length);

        for (uint i = 0; i < allResumes.length; i++) {
            if (resumeApprovals[_recruiterAddress][allResumes[i]]) {
                arrResume[i] = resumes[allResumes[i]];
            }
        }

        return arrResume;
    }

    function _getAllApprovedRecruitersOf(
        uint _resumeId
    ) public view returns (IUser.AppUser[] memory) {
        IUser.AppUser[] memory arrRecruiter = user.getAllRecruiters();
        IUser.AppUser[] memory arrApprovedRecruiter = new IUser.AppUser[](
            arrRecruiter.length
        );

        for (uint i = 0; i < arrRecruiter.length; i++) {
            if (resumeApprovals[arrRecruiter[i].accountAddress][_resumeId]) {
                arrApprovedRecruiter[i] = arrRecruiter[i];
            }
        }

        return arrApprovedRecruiter;
    }

    // only candidate role -> later⏳
    // resume must existed -> done✅
    // candidate must own resume -> later⏳
    // just aprrove for recruiter -> done✅
    // recruiter have not been approved yet -> done✅
    function _connectResumeRecruiter(
        address _recruiterAddress,
        uint _resumeId
    ) internal {
        if (!resumes[_resumeId].exist) {
            revert Resume__NotExisted({id: _resumeId});
        }
        // if (isOwnerOfResume(msg.sender, _resumeId)) {
        //     revert Candidate_Resume__NotOwned({
        //         id: _resumeId,
        //         candidate_address: msg.sender
        //     });
        // }
        if (
            !(user.isExisted(_recruiterAddress) &&
                user.hasType(_recruiterAddress, 1))
        ) {
            revert Recruiter__NotExisted({user_address: _recruiterAddress});
        }
        if (resumeApprovals[_recruiterAddress][_resumeId]) {
            revert Recruiter_Resume__AlreadyApproved({
                recruiter_address: _recruiterAddress,
                id: _resumeId
            });
        }

        resumeApprovals[_recruiterAddress][_resumeId] = true;
        address ownerAddress = candidateOwnResume[_resumeId];

        emit Approval(
            ownerAddress,
            _recruiterAddress,
            _resumeId,
            resumeApprovals[_recruiterAddress][_resumeId]
        );
    }

    // only candidate -> later⏳
    // resume must existed -> done✅
    // candidate must own resume -> later⏳
    // just disaprrove for recruiter -> done✅
    // recruiter have been approved -> done✅
    function _disconnectResumeRecruiter(
        address _recruiterAddress,
        uint _resumeId
    ) internal {
        if (!resumes[_resumeId].exist) {
            revert Resume__NotExisted({id: _resumeId});
        }
        // if (isOwnerOfResume(msg.sender, _resumeId)) {
        //     revert Candidate_Resume__NotOwned({
        //         id: _resumeId,
        //         candidate_address: msg.sender
        //     });
        // }
        if (
            !(user.isExisted(_recruiterAddress) &&
                user.hasType(_recruiterAddress, 1))
        ) {
            revert Recruiter__NotExisted({user_address: _recruiterAddress});
        }
        if (!resumeApprovals[_recruiterAddress][_resumeId]) {
            revert Recruiter_Resume__NotApproved({
                recruiter_address: _recruiterAddress,
                id: _resumeId
            });
        }

        resumeApprovals[_recruiterAddress][_resumeId] = false;
        address ownerAddress = candidateOwnResume[_resumeId];

        emit Approval(
            ownerAddress,
            _recruiterAddress,
            _resumeId,
            resumeApprovals[_recruiterAddress][_resumeId]
        );
    }

    //======================FOR INTERFACE==========================
    function isOwnerOfResume(
        address _candidateAddress,
        uint _id
    ) external view returns (bool) {
        return _isOwnerOfResume(_candidateAddress, _id);
    }

    function getResume(uint _id) external view returns (AppResume memory) {
        return _getResume(_id);
    }

    function getAllResumes() external view returns (AppResume[] memory) {
        return _getAllResumes();
    }

    function getAllResumesOf(
        address _candidateAddress
    ) external view returns (AppResume[] memory) {
        return _getAllResumesOf(_candidateAddress);
    }

    function addResume(
        uint _id,
        string memory _data,
        uint _createAt,
        address _candidateAddress
    ) external {
        _addResume(_id, _data, _createAt, _candidateAddress);
    }

    function updateResume(
        uint _id,
        string memory _data,
        uint256 _updateAt
    ) external {
        _updateResume(_id, _data, _updateAt);
    }

    function deleteResume(uint _id) external {
        _deleteResume(_id);
    }

    function isExistedResumeRecruiter(
        address _recruiterAddress,
        uint _resumeId
    ) external view returns (bool) {
        return _isExistedResumeRecruiter(_recruiterAddress, _resumeId);
    }

    function getAllApprovedResumesOf(
        address _recruiterAddress
    ) external view returns (AppResume[] memory) {
        return _getAllApprovedResumesOf(_recruiterAddress);
    }

    function getAllApprovedRecruitersOf(
        uint _resumeId
    ) external view returns (IUser.AppUser[] memory) {
        return _getAllApprovedRecruitersOf(_resumeId);
    }

    function connectResumeRecruiter(
        address _recruiterAddress,
        uint _resumeId
    ) external {
        _connectResumeRecruiter(_recruiterAddress, _resumeId);
    }

    function disconnectResumeRecruiter(
        address _recruiterAddress,
        uint _resumeId
    ) external {
        _disconnectResumeRecruiter(_recruiterAddress, _resumeId);
    }

    //======================USER CONTRACT==========================
    function setUserInterface(address _contract) public {
        user = IUser(_contract);
    }
}
