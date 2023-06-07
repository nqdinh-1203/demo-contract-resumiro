// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ICertificate {
    struct AppCertificate {
        string name;
        uint verifiedAt;
        string certificateAddress;
        address candidate;
        address verifier;
        DocStatus status;
    }

    enum DocStatus {
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
        address _candidateAddress,
        address _verifierAddress,
        string memory _certificateAddress
    ) external;

    function updateCertificate(
        uint _id,
        string memory _name,
        address _verifierAddress,
        string memory _certificateAddress
    ) external;

    function changeCertificateStatus(uint _id, uint _status, uint _verifiedAt) external;

    function deleteCertificate(uint _id) external;

    function getCertificate(
        string memory _certificateAddress
        // uint _id
    ) external view returns (AppCertificate memory);

    function getCertificateVerifier(
        address _verifierAddress
    ) external view returns (AppCertificate[] memory);

    function getCertificateCandidate(
        address _candidateAddress
    ) external view returns (AppCertificate[] memory);
}
