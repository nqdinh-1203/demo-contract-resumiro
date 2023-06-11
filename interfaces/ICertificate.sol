// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ICertificate {
    struct AppCertificate {
        string name;
        uint expiredAt;
        string certificateAddress;
        address candidate;
        address verifier;
        uint companyId;
        CertStatus status;
    }

    enum CertStatus {
        Pending,
        Verified,
        Rejected
    }

    function isOwnerOfCertificate(
        address _candidateAddress,
        uint _id
    ) external view returns (bool);

    function isVerifierOfCertificate(
        address _verifierAddress,
        uint _id
    ) external view returns (bool);

    function addCertificate(
        string memory _name,
        string memory _certificateAddress,
        address _candidateAddress,
        address _verifierAddress,
        uint _companyId
    ) external;

    function updateCertificate(
        uint _id,
        string memory _name,
        string memory _certificateAddress,
        address _verifierAddress,
        uint _companyId
    ) external;

    function changeCertificateStatus(
        uint _id,
        uint _status,
        uint _expiredAt
    ) external;

    function deleteCertificate(uint _id) external;

    function getCertificate(
        string memory _certificateAddress
    ) external view returns (AppCertificate memory);

    function getCertificateVerifier(
        address _verifierAddress
    ) external view returns (AppCertificate[] memory);

    function getCertificateCandidate(
        address _candidateAddress
    ) external view returns (AppCertificate[] memory);
}
