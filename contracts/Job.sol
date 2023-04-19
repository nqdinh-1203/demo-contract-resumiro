// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Job {
    struct AppJob {
        string title;
        string location;
        string jobType;
        uint createAt;
        uint updateAt;
        uint companyId;
        uint salary;
        string field;
        bool exist;
    }

    mapping(uint => AppJob) public jobs;
    mapping(address => mapping(uint => bool)) public candidateApplyJob;
    mapping(uint => address) public recruiterOwnJob;

    event AddJob(
        uint id,
        string title,
        string location,
        string job_type,
        uint create_at,
        uint update_at,
        uint companyId,
        uint salary,
        string field,
        address owner_address
    );
    event UpdateJob(
        uint id,
        string title,
        string location,
        string job_type,
        uint create_at,
        uint update_at,
        uint companyId,
        uint salary,
        string field,
        address owner_address
    );
    event DeleteJob(
        uint id,
        string title,
        string location,
        string job_type,
        uint create_at,
        uint update_at,
        uint companyId,
        uint salary,
        string field,
        address owner_address
    );
    event ApplyJob(
        address indexed candidate_address,
        address indexed recruiter_address,
        uint job_id,
        bool isApplied
    );
    event DisapplyJob(
        address indexed candidate_address,
        address indexed recruiter_address,
        uint job_id,
        bool isApplied
    );

    // modifier onlyOwnJob(uint _id) {
    //     require(
    //         recruiterOwnJob[_id] == msg.sender,
    //         "Recruiter: Caller not own this job"
    //     );
    //     _;
    // }

    function getJob(uint _id) public view returns (AppJob memory) {
        return jobs[_id];
    }

    // only recruiter -> resumiro
    // param _recruiterAddress must equal msg.sender -> resumiro
    // recruiter must connected with company id -> resumiro
    // job id must not existed
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
    ) public virtual {
        require(!jobs[_id].exist, "Job: id already existed");

        jobs[_id] = AppJob(
            _title,
            _location,
            _jobType,
            _createAt,
            _createAt,
            _companyId,
            _salary,
            _field,
            true
        );

        AppJob memory job = getJob(_id);
        recruiterOwnJob[_id] = _recruiterAddress;
        address owner = recruiterOwnJob[_id];

        emit AddJob(
            _id,
            job.title,
            job.location,
            job.jobType,
            job.createAt,
            job.updateAt,
            job.companyId,
            job.salary,
            job.field,
            owner
        );
    }

    // only recruiter -> resumiro
    // only owner of job -> resumiro
    // recruiter must connected with update company -> resumiro
    // job id must existed
    function updateJob(
        uint _id,
        string memory _title,
        string memory _location,
        string memory _jobType,
        uint _updateAt,
        uint _companyId,
        uint _salary,
        string memory _field
    ) public virtual {
        require(jobs[_id].exist, "Job: id not existed");

        jobs[_id].title = _title;
        jobs[_id].location = _location;
        jobs[_id].jobType = _jobType;
        jobs[_id].updateAt = _updateAt;
        jobs[_id].companyId = _companyId;
        jobs[_id].salary = _salary;
        jobs[_id].field = _field;

        AppJob memory job = getJob(_id);
        address owner = recruiterOwnJob[_id];

        emit UpdateJob(
            _id,
            job.title,
            job.location,
            job.jobType,
            job.createAt,
            job.updateAt,
            job.companyId,
            job.salary,
            job.field,
            owner
        );
    }

    // only recruiter -> resumiro
    // only owner of job -> resumiro
    // job id must existed
    function deleteJob(uint _id) public virtual {
        require(jobs[_id].exist, "Job: id not existed");

        AppJob memory job = getJob(_id);
        address ownerOfJob = recruiterOwnJob[_id];

        delete jobs[_id];
        delete recruiterOwnJob[_id];

        emit DeleteJob(
            _id,
            job.title,
            job.location,
            job.jobType,
            job.createAt,
            job.updateAt,
            job.companyId,
            job.salary,
            job.field,
            ownerOfJob
        );
    }

    // only candidate -> resumiro
    // param _candidateAddress must equal msg.sender -> resumiro
    // job must existed
    // candidate have not applied this job yet
    function connectJobCandidate(
        address _candidateAddress,
        uint _jobId
    ) public virtual {
        require(jobs[_jobId].exist, "Job-Applicant: id not existed");
        require(
            !candidateApplyJob[_candidateAddress][_jobId],
            "Job-Applicant: Candidate already applied this job"
        );

        candidateApplyJob[_candidateAddress][_jobId] = true;
        address owner = recruiterOwnJob[_jobId];
        bool isApplied = candidateApplyJob[_candidateAddress][_jobId];

        emit ApplyJob(_candidateAddress, owner, _jobId, isApplied);
    }

    // only candidate -> resumiro
    // param _candidateAddress must equal msg.sender -> resumiro
    // job must existed
    // candidate have applied this job
    function disconnectJobCandidate(
        address _candidateAddress,
        uint _jobId
    ) public virtual {
        require(jobs[_jobId].exist, "Job-Applicant: id not existed");
        require(
            candidateApplyJob[_candidateAddress][_jobId],
            "Job-Applicant: Candidate not applied this job"
        );

        candidateApplyJob[_candidateAddress][_jobId] = false;
        address owner = recruiterOwnJob[_jobId];
        bool isApplied = candidateApplyJob[_candidateAddress][_jobId];

        emit DisapplyJob(_candidateAddress, owner, _jobId, isApplied);
    }
}
