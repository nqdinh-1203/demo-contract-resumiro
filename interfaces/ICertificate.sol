// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ICertificate {
    struct AppCertificate {
        string name;
        uint verifiedAt;
        bool exist;
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
        // uint _id,
        string memory _name,
        uint _verifiedAt,
        address _candidateAddress,
        address _verifierAddress,
        string memory _certificateAddress
    ) external;

    function updateCertificate(
        uint _id,
        uint _verifiedAt,
        address _verifierAddress,
        string memory _certificateAddress,
        DocStatus _status
    ) external;

    function deleteCertificate(uint _id) external;

    function getDocument(
        string memory _certificateAddress
    )
        external
        view
        returns (
            string memory name,
            address requester,
            address verifier,
            uint verifiedAt,
            DocStatus status
        );

    function getCount(address _addressUser) external view returns (uint);

    function getCertificateVerifier(
        address _verifierAddress,
        uint lindex
    )
        external
        view
        returns (
            string memory name,
            address candidate,
            uint verifiedAt,
            string memory certificateAddress,
            DocStatus status,
            uint index
        );

    function getCertificatecandidate(
        address _candidateAddress,
        uint lindex
    )
        external
        view
        returns (
            string memory name,
            address verifier,
            uint verifiedAt,
            string memory certificateAddress,
            DocStatus status,
            uint index
        );
}
