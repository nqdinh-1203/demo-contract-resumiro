// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Resume {
    struct AppResume {
        string data;
        uint createAt;
        uint updateAt;
        bool exist;
    }

    mapping(uint => AppResume) public resumes;
    mapping(address => mapping(uint => bool)) public resumeApprovals;
    mapping(uint => address) public candidateOwnResume;

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

    function getResume(uint _id) public view returns (AppResume memory) {
        return resumes[_id];
    }

    // only candidate -> resumiro
    // param _candidateAddress must equal msg.sender -> resumiro
    // resume must not existed
    function addResume(
        uint _id,
        string memory _data,
        uint _createAt,
        address _candidateAddress
    ) public virtual {
        require(!resumes[_id].exist, "Resume: resume id already existed");

        resumes[_id].data = _data;
        resumes[_id].createAt = _createAt;
        resumes[_id].updateAt = _createAt;
        resumes[_id].exist = true;

        candidateOwnResume[_id] = _candidateAddress;

        AppResume memory resume = getResume(_id);
        address owner = candidateOwnResume[_id];

        emit AddResume(
            _id,
            resume.data,
            resume.createAt,
            resume.updateAt,
            owner
        );
    }

    // only candidate -> resumiro
    // candidate must own resume -> resumiro
    // resume must existed
    function updateResume(
        uint _id,
        string memory _data,
        uint256 _updateAt
    ) public virtual {
        require(resumes[_id].exist, "Resume: resume id not exist");

        resumes[_id].data = _data;
        resumes[_id].updateAt = _updateAt;

        AppResume memory resume = getResume(_id);
        address owner = candidateOwnResume[_id];

        emit UpdateResume(
            _id,
            resume.data,
            resume.createAt,
            resume.updateAt,
            owner
        );
    }

    // only candidate -> resumiro
    // candidate must own resume -> resumiro
    // resume must existed
    function deleteResume(uint _id) public virtual {
        require(resumes[_id].exist, "Resume: resume id not exist");

        AppResume memory resume = getResume(_id);
        address ownerAddress = candidateOwnResume[_id];

        delete resumes[_id];

        emit DeleteResume(
            _id,
            resume.data,
            resume.createAt,
            resume.updateAt,
            ownerAddress
        );
    }

    function isExistedResumeRecruiter(
        address _recruiterAddress,
        uint _resumeId
    ) public view returns (bool) {
        return resumeApprovals[_recruiterAddress][_resumeId];
    }

    // only candidate -> resumiro
    // candidate must own resume -> resumiro
    // just aprrove for recruiter -> resumiro
    // resume must existed
    // recruiter have not been approved yet
    function connectResumeRecruiter(
        address _recruiterAddress,
        uint _resumeId
    ) public virtual {
        require(
            resumes[_resumeId].exist,
            "Approval resume: resume id not exist"
        );
        require(
            !isExistedResumeRecruiter(_recruiterAddress, _resumeId),
            "Approval resume: Recruiter already approved"
        );

        resumeApprovals[_recruiterAddress][_resumeId] = true;
        address ownerAddress = candidateOwnResume[_resumeId];

        emit Approval(
            ownerAddress,
            _recruiterAddress,
            _resumeId,
            resumeApprovals[_recruiterAddress][_resumeId]
        );
    }

    // only candidate -> resumiro
    // candidate must own resume -> resumiro
    // just aprrove for recruiter -> resumiro
    // resume must existed
    // recruiter have been approved
    function disconnectResumeRecruiter(
        address _recruiterAddress,
        uint _resumeId
    ) public virtual {
        require(
            resumes[_resumeId].exist,
            "Dispproval resume: resume id not exist"
        );
        require(
            isExistedResumeRecruiter(_recruiterAddress, _resumeId),
            "Dispproval resume: Recruiter not been approved"
        );

        resumeApprovals[_recruiterAddress][_resumeId] = false;
        address ownerAddress = candidateOwnResume[_resumeId];

        emit Approval(
            ownerAddress,
            _recruiterAddress,
            _resumeId,
            resumeApprovals[_recruiterAddress][_resumeId]
        );
    }
}
