// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IUser.sol";
import "../interfaces/IResume.sol";
import "./library/UintArray.sol";
import "./library/EnumrableSet.sol";

contract Resume is IResume {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant CANDIDATE_ROLE = keccak256("CANDIDATE_ROLE");

    //=============================ATTRIBUTES==========================================
    EnumerableSet.UintSet resumeIds;
    uint resumeCounter = 1;
    mapping(uint => AppResume) public resumes;
    mapping(address => EnumerableSet.UintSet) resumeApprovals;
    mapping(uint => address) candidateOwnResume;

    IUser public user;

    constructor(address _contract) {
        user = IUser(_contract);
    }

    //=============================EVENTS==========================================
    event AddResume(
        uint id,
        string data,
        address indexed owner,
        string title,
        uint create_at
    );
    event DeleteResume(
        uint id,
        string data,
        address indexed owner,
        string title,
        uint create_at
    );
    // event UpdateResume(
    //     uint id,
    //     string data,
    //     address indexed owner,
    //     string title,
    //     uint create_at
    // );
    event Approval(
        address candidate_address,
        address recruiter_address,
        uint resume_id,
        bool isApproved
    );

    //=============================ERRORS==========================================
    error User__NoRole(address account);

    error Resume__NotExisted(uint id);
    error Resume__AlreadyExisted(uint id);

    error Candidate_Resume__NotOwned(address candidate_address, uint id);
    error Candidate_Resume__NotForSelf(
        address candidate_address,
        address origin_address
    );

    error Recruiter__NotExisted(address user_address);
    error Candidate__NotExisted(address user_address);

    error Recruiter_Resume__NotApproved(address recruiter_address, uint id);
    error Recruiter_Resume__AlreadyApproved(address recruiter_address, uint id);

    //=============================METHODS==========================================
    modifier onlyRole(bytes32 _role) {
        if (!user.hasRole(tx.origin, _role)) {
            revert User__NoRole({account: tx.origin});
        }
        _;
    }

    modifier onlyOwner(uint _id) {
        if (!_isOwnerOfResume(tx.origin, _id)) {
            revert Candidate_Resume__NotOwned({
                id: _id,
                candidate_address: tx.origin
            });
        }
        _;
    }

    modifier onlySelf(address _account) {
        if (_account != tx.origin) {
            revert Candidate_Resume__NotForSelf({
                candidate_address: _account,
                origin_address: tx.origin
            });
        }
        _;
    }

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
        AppResume[] memory resumeArr = new AppResume[](resumeIds.length());

        for (uint i = 0; i < resumeIds.length(); i++) {
            resumeArr[i] = resumes[resumeIds.at(i)];
        }

        return resumeArr;
    }

    function _getAllResumesOf(
        address _candidateAddress
    ) internal view returns (AppResume[] memory) {
        AppResume[] memory resumeArr = new AppResume[](resumeIds.length());

        for (uint i = 0; i < resumeIds.length(); i++) {
            if (resumes[resumeIds.at(i)].owner == _candidateAddress)
                resumeArr[i] = resumes[resumeIds.at(i)];
        }

        return resumeArr;
    }

    // only candidate -> later⏳ -> done✅
    // param _candidateAddress must equal msg.sender -> later⏳ -> done✅
    // resume must not existed -> done✅
    // just add for candidate -> done✅
    function _addResume(
        string memory _data,
        address _candidateAddress,
        string memory _title,
        uint _createAt
    ) internal onlyRole(CANDIDATE_ROLE) onlySelf(_candidateAddress) {
        uint _id = resumeCounter;
        resumeCounter++;

        if (resumeIds.contains(_id)) {
            revert Resume__AlreadyExisted({id: _id});
        }
        if (
            !(user.isExisted(_candidateAddress) &&
                user.hasType(_candidateAddress, 0))
        ) {
            revert Candidate__NotExisted({user_address: _candidateAddress});
        }

        resumes[_id] = AppResume(
            _id,
            _data,
            _candidateAddress,
            _title,
            _createAt
        );

        candidateOwnResume[_id] = _candidateAddress;
        resumeIds.add(_id);

        AppResume memory resume = _getResume(_id);

        emit AddResume(
            _id,
            resume.data,
            resume.owner,
            resume.title,
            resume.createAt
        );
    }

    // only candidate -> later⏳
    // resume must existed -> done✅
    // caller must own resume -> later⏳
    // caller must be candidate in user contract -> later⏳
    // function _updateResume(
    //     uint _id,
    //     string memory _data,
    //     uint256 _updateAt
    // ) internal {
    //     if (!resumes[_id].exist) {
    //         revert Resume__NotExisted({id: _id});
    //     }
    //     // if (isOwnerOfResume(msg.sender, _id)) {
    //     //     revert Candidate_Resume__NotOwned({id: _id, candidate_address: msg.sender});
    //     // }

    //     resumes[_id].data = _data;
    //     resumes[_id].updateAt = _updateAt;

    //     AppResume memory resume = _getResume(_id);
    //     address owner = candidateOwnResume[_id];

    //     emit UpdateResume(
    //         _id,
    //         resume.data,
    //         resume.createAt,
    //         resume.updateAt,
    //         owner
    //     );
    // }

    // only candidate -> later⏳ -> done✅
    // resume must existed -> done✅
    // caller must own resume -> later⏳ -> done✅
    // caller must be candidate in user contract -> later⏳
    function _deleteResume(
        uint _id
    ) internal onlyRole(CANDIDATE_ROLE) onlyOwner(_id) {
        if (!resumeIds.contains(_id)) {
            revert Resume__NotExisted({id: _id});
        }

        AppResume memory resume = _getResume(_id);

        // address owner = resume.owner;

        resumeIds.remove(_id);
        delete candidateOwnResume[_id];
        delete resumes[_id];

        emit DeleteResume(
            _id,
            resume.data,
            resume.owner,
            resume.title,
            resume.createAt
        );
    }

    //======================RESUME-RECRUITER==========================
    function _isExistedResumeRecruiter(
        address _recruiterAddress,
        uint _resumeId
    ) internal view returns (bool) {
        return resumeApprovals[_recruiterAddress].contains(_resumeId);
    }

    function _getAllApprovedResumesOf(
        address _recruiterAddress
    ) internal view returns (AppResume[] memory) {
        AppResume[] memory resumeArr = new AppResume[](
            resumeApprovals[_recruiterAddress].length()
        );

        for (uint i = 0; i < resumeArr.length; i++) {
            resumeArr[i] = resumes[resumeApprovals[_recruiterAddress].at(i)];
        }

        return resumeArr;
    }

    // new ⭐ -> change AppUser[] to address[]
    function _getAllApprovedRecruitersOf(
        uint _resumeId
    ) public view returns (address[] memory) {
        address[] memory recruiterArr = user.getAllRecruiters();
        address[] memory arrApprovedRecruiter = new address[](
            recruiterArr.length
        );

        for (uint i = 0; i < recruiterArr.length; i++) {
            if (resumeApprovals[recruiterArr[i]].contains(_resumeId)) {
                arrApprovedRecruiter[i] = recruiterArr[i];
            }
        }

        return arrApprovedRecruiter;
    }

    // only candidate role -> later⏳ -> done✅
    // resume must existed -> done✅
    // candidate must own resume -> later⏳ -> done✅
    // just aprrove for recruiter -> done✅
    // recruiter have not been approved yet -> done✅
    function _connectResumeRecruiter(
        address _recruiterAddress,
        uint _resumeId
    ) internal onlyRole(CANDIDATE_ROLE) onlyOwner(_resumeId) {
        if (!resumeIds.contains(_resumeId)) {
            revert Resume__NotExisted({id: _resumeId});
        }

        if (
            !(user.isExisted(_recruiterAddress) &&
                (user.hasType(_recruiterAddress, 1) ||
                    user.hasType(_recruiterAddress, 2)))
        ) {
            revert Recruiter__NotExisted({user_address: _recruiterAddress});
        }
        if (resumeApprovals[_recruiterAddress].contains(_resumeId)) {
            revert Recruiter_Resume__AlreadyApproved({
                recruiter_address: _recruiterAddress,
                id: _resumeId
            });
        }

        resumeApprovals[_recruiterAddress].add(_resumeId);
        address ownerAddress = candidateOwnResume[_resumeId];
        bool isApproved = resumeApprovals[_recruiterAddress].contains(
            _resumeId
        );

        emit Approval(ownerAddress, _recruiterAddress, _resumeId, isApproved);
    }

    // only candidate -> later⏳ -> done✅
    // resume must existed -> done✅
    // candidate must own resume -> later⏳ -> done✅
    // just disaprrove for recruiter -> done✅
    // recruiter have been approved -> done✅
    function _disconnectResumeRecruiter(
        address _recruiterAddress,
        uint _resumeId
    ) internal onlyRole(CANDIDATE_ROLE) onlyOwner(_resumeId) {
        if (!resumeIds.contains(_resumeId)) {
            revert Resume__NotExisted({id: _resumeId});
        }
        if (
            !(user.isExisted(_recruiterAddress) &&
                (user.hasType(_recruiterAddress, 1) ||
                    user.hasType(_recruiterAddress, 2)))
        ) {
            revert Recruiter__NotExisted({user_address: _recruiterAddress});
        }
        if (!resumeApprovals[_recruiterAddress].contains(_resumeId)) {
            revert Recruiter_Resume__NotApproved({
                recruiter_address: _recruiterAddress,
                id: _resumeId
            });
        }

        resumeApprovals[_recruiterAddress].remove(_resumeId);
        address ownerAddress = candidateOwnResume[_resumeId];
        bool isApproved = resumeApprovals[_recruiterAddress].contains(
            _resumeId
        );

        emit Approval(ownerAddress, _recruiterAddress, _resumeId, isApproved);
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
        string memory _data,
        address _candidateAddress,
        string memory _title,
        uint _createAt
    ) external {
        _addResume(_data, _candidateAddress, _title, _createAt);
    }

    // function updateResume(
    //     uint _id,
    //     string memory _data,
    //     string memory _title,
    //     uint256 _updateAt
    // ) external {
    //     _updateResume(_id, _data, _updateAt);
    // }

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
    ) external view returns (address[] memory) {
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
