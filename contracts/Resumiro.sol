// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.18;

// import "./abstract-contract/AccessControl.sol";
// import "./abstract-contract/Ownable.sol";

// import "./User.sol";
// import "./Company.sol";
// import "./Certificate.sol";
// import "./Resume.sol";
// import "./Job.sol";

// contract Resumiro is
//     Ownable,
//     AccessControl,
//     User,
//     Company,
//     Certificate,
//     Resume,
//     Job
// {
//     /**
//      * @custom:resumiro
//      * */
//     constructor() {
//         _setRole(owner(), ADMIN_ROLE);
//     }

//     /**
//      * @custom:user-contract
//      * */
//     modifier onlyUserWithType(uint _type) {
//         require(users[msg.sender].exist, "User: Caller not a user");
//         require(
//             users[msg.sender].userType == UserType(_type),
//             "User: Caller not a user with needed role"
//         );
//         _;
//     }

//     function addUser(
//         address _userAddress,
//         uint _type
//     ) public override onlyRole(ADMIN_ROLE) {
//         super.addUser(_userAddress, _type);
//     }

//     function deleteUser(
//         address _userAddress
//     ) public override onlyRole(ADMIN_ROLE) {
//         super.deleteUser(_userAddress);
//     }

//     /**
//      * @custom:company-contract
//      * */
//     function addCompany(
//         uint _id,
//         string memory _name,
//         string memory _website,
//         string memory _location,
//         string memory _addr
//     ) public override onlyRole(ADMIN_ROLE) {
//         super.addCompany(_id, _name, _website, _location, _addr);
//     }

//     function updateCompany(
//         uint _id,
//         string memory _name,
//         string memory _website,
//         string memory _location,
//         string memory _addr
//     ) public override onlyRole(ADMIN_ROLE) {
//         super.updateCompany(_id, _name, _website, _location, _addr);
//     }

//     function deleteCompany(uint _id) public override onlyRole(ADMIN_ROLE) {
//         super.deleteCompany(_id);
//     }

//     function connectCompanyRecruiter(
//         address _recruiterAddress,
//         uint _companyId
//     ) public override onlyUserWithType(1) onlyRole(RECRUITER_ROLE) {
//         require(
//             msg.sender == _recruiterAddress,
//             "Company-Recruiter: param not match with caller"
//         );

//         super.connectCompanyRecruiter(_recruiterAddress, _companyId);
//     }

//     function disconnectCompanyRecruiter(
//         address _recruiterAddress,
//         uint _companyId
//     ) public override onlyUserWithType(1) onlyRole(RECRUITER_ROLE) {
//         require(
//             msg.sender == _recruiterAddress,
//             "Company-Recruiter: param not match with caller"
//         );

//         super.disconnectCompanyRecruiter(_recruiterAddress, _companyId);
//     }

//     /**
//      * @custom:certificate-contract
//      * */
//     function isOwnerOfCertificate(
//         address _candidateAddress,
//         uint _id
//     ) public view returns (bool) {
//         return candidateOwnCert[_id] == _candidateAddress;
//     }

//     modifier onlyOwnCertificate(uint _id) {
//         require(
//             isOwnerOfCertificate(msg.sender, _id),
//             "Certificate: Caller not own this certificate"
//         );
//         _;
//     }

//     function addCertificate(
//         uint _id,
//         string memory _name,
//         uint _verifiedAt,
//         address _candidateAddress
//     ) public override onlyUserWithType(0) onlyRole(CANDIDATE_ROLE) {
//         require(
//             msg.sender == _candidateAddress,
//             "Certificate: param not match with caller"
//         );

//         super.addCertificate(_id, _name, _verifiedAt, _candidateAddress);
//     }

//     function updateCertificate(
//         uint _id,
//         string memory _name,
//         uint _verifiedAt
//     )
//         public
//         override
//         onlyUserWithType(0)
//         onlyRole(CANDIDATE_ROLE)
//         onlyOwnCertificate(_id)
//     {
//         super.updateCertificate(_id, _name, _verifiedAt);
//     }

//     function deleteCertificate(
//         uint _id
//     )
//         public
//         override
//         onlyUserWithType(0)
//         onlyRole(CANDIDATE_ROLE)
//         onlyOwnCertificate(_id)
//     {
//         super.deleteCertificate(_id);
//     }

//     /**
//      * @custom:resume-contract
//      * */
//     function isOwnerOfResume(
//         address _candidateAddress,
//         uint _id
//     ) public view returns (bool) {
//         return candidateOwnResume[_id] == _candidateAddress;
//     }

//     modifier onlyOwnResume(uint _id) {
//         require(isOwnerOfResume(msg.sender, _id), "Resume: Caller not own this resume");
//         _;
//     }

//     function addResume(
//         uint _id,
//         string memory _data,
//         uint _createAt,
//         address _candidateAddress
//     ) public override onlyUserWithType(0) onlyRole(CANDIDATE_ROLE) {
//         require(
//             msg.sender == _candidateAddress,
//             "Resume: param not match with caller"
//         );

//         super.addResume(_id, _data, _createAt, _candidateAddress);
//     }

//     function updateResume(
//         uint _id,
//         string memory _data,
//         uint256 _updateAt
//     )
//         public
//         override
//         onlyUserWithType(0)
//         onlyRole(CANDIDATE_ROLE)
//         onlyOwnResume(_id)
//     {
//         super.updateResume(_id, _data, _updateAt);
//     }

//     function deleteResume(
//         uint _id
//     )
//         public
//         override
//         onlyUserWithType(0)
//         onlyRole(CANDIDATE_ROLE)
//         onlyOwnResume(_id)
//     {
//         super.deleteResume(_id);
//     }

//     modifier justApproveRecruiter(address _recruiterAddress) {
//         require(
//             hasRole(_recruiterAddress, RECRUITER_ROLE),
//             "Approval resume: param not the recruiter access"
//         );
//         require(
//             users[_recruiterAddress].exist &&
//                 users[_recruiterAddress].userType == UserType(1),
//             "Approval resume: param not the recruiter"
//         );
//         _;
//     }

//     function connectResumeRecruiter(
//         address _recruiterAddress,
//         uint _resumeId
//     )
//         public
//         override
//         onlyUserWithType(0)
//         onlyRole(CANDIDATE_ROLE)
//         onlyOwnResume(_resumeId)
//         justApproveRecruiter(_recruiterAddress)
//     {
//         super.connectResumeRecruiter(_recruiterAddress, _resumeId);
//     }

//     function disconnectResumeRecruiter(
//         address _recruiterAddress,
//         uint _resumeId
//     )
//         public
//         override
//         onlyUserWithType(0)
//         onlyRole(CANDIDATE_ROLE)
//         onlyOwnResume(_resumeId)
//         justApproveRecruiter(_recruiterAddress)
//     {
//         super.disconnectResumeRecruiter(_recruiterAddress, _resumeId);
//     }

//     /**
//      * @custom:job-contract
//      * */
//     function isOwnerOfJob(
//         address _recruiterAddress,
//         uint _jobId
//     ) public view returns (bool) {
//         return recruiterOwnJob[_jobId] == _recruiterAddress;
//     }

//     modifier onlyOwnJob(uint _id) {
//         require(isOwnerOfJob(msg.sender, _id), "Job: Caller not own this job");
//         _;
//     }

//     function addJob(
//         uint _id,
//         string memory _title,
//         string memory _location,
//         string memory _jobType,
//         uint _createAt,
//         uint _companyId,
//         uint _salary,
//         string memory _field,
//         address _recruiterAddress
//     ) public override onlyRole(RECRUITER_ROLE) onlyUserWithType(1) {
//         require(
//             msg.sender == _recruiterAddress,
//             "Job: param not match with caller"
//         );
//         require(
//             isExistedCompanyRecruiter(_recruiterAddress, _companyId),
//             "Job: recruiter not in company"
//         );

//         super.addJob(
//             _id,
//             _title,
//             _location,
//             _jobType,
//             _createAt,
//             _companyId,
//             _salary,
//             _field,
//             _recruiterAddress
//         );
//     }

//     function updateJob(
//         uint _id,
//         string memory _title,
//         string memory _location,
//         string memory _jobType,
//         uint _createAt,
//         uint _companyId,
//         uint _salary,
//         string memory _field
//     )
//         public
//         override
//         onlyRole(RECRUITER_ROLE)
//         onlyUserWithType(1)
//         onlyOwnJob(_id)
//     {
//         require(
//             isExistedCompanyRecruiter(msg.sender, _companyId),
//             "Job: recruiter not in company"
//         );

//         super.updateJob(
//             _id,
//             _title,
//             _location,
//             _jobType,
//             _createAt,
//             _companyId,
//             _salary,
//             _field
//         );
//     }

//     function deleteJob(
//         uint _id
//     )
//         public
//         override
//         onlyUserWithType(1)
//         onlyRole(RECRUITER_ROLE)
//         onlyOwnJob(_id)
//     {
//         super.deleteJob(_id);
//     }

//     function connectJobCandidate(
//         address _candidateAddress,
//         uint _jobId
//     ) public override onlyRole(CANDIDATE_ROLE) onlyUserWithType(0) {
//         require(
//             msg.sender == _candidateAddress,
//             "Job-Applicant: param not match with caller"
//         );

//         super.connectJobCandidate(_candidateAddress, _jobId);
//     }

//     function disconnectJobCandidate(
//         address _candidateAddress,
//         uint _jobId
//     ) public override onlyRole(CANDIDATE_ROLE) onlyUserWithType(0) {
//         require(
//             msg.sender == _candidateAddress,
//             "Job-Applicant: param not match with caller"
//         );

//         super.disconnectJobCandidate(_candidateAddress, _jobId);
//     }
// }
