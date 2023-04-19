// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Certificate {
    struct AppCertificate {
        string name;
        uint verifiedAt;
        bool exist;
    }

    mapping(uint => AppCertificate) certs;
    mapping(uint => address) candidateOwnCert;

    event AddCertificate(
        uint id,
        string name,
        uint verified_at,
        address indexed owner_address
    );
    event UpdateCertificate(
        uint id,
        string name,
        uint verified_at,
        address indexed owner_address
    );
    event DeleteCertificate(
        uint id,
        string name,
        uint verified_at,
        address indexed owner_address
    );

    // only candidate -> resumiro
    // param _candidateAddress must equal msg.sender -> resumiro
    // id must not existed
    function addCertificate(
        uint _id,
        string memory _name,
        uint _verifiedAt,
        address _candidateAddress
    ) public virtual {
        require(!certs[_id].exist, "Certificate: ID already existed");

        certs[_id] = AppCertificate(_name, _verifiedAt, true);
        candidateOwnCert[_id] = _candidateAddress;

        AppCertificate memory cert = certs[_id];

        emit AddCertificate(_id, cert.name, cert.verifiedAt, _candidateAddress);
    }

    // only candidate -> resumiro
    // candidate must own certificate -> resumiro
    // id must not existed
    function updateCertificate(
        uint _id,
        string memory _name,
        uint _verifiedAt
    ) public virtual {
        require(certs[_id].exist, "Certificate: ID not existed");

        certs[_id].name = _name;
        certs[_id].verifiedAt = _verifiedAt;
        AppCertificate memory cert = certs[_id];

        address candidateAddress = candidateOwnCert[_id];

        emit UpdateCertificate(
            _id,
            cert.name,
            cert.verifiedAt,
            candidateAddress
        );
    }

    // only candidate -> resumiro
    // candidate must own certificate -> resumiro
    // id must not existed
    function deleteCertificate(uint _id) public virtual {
        require(certs[_id].exist, "Certificate: ID not existed");

        AppCertificate memory certificate = certs[_id];
        address ownerAddress = candidateOwnCert[_id];

        delete certs[_id];
        delete candidateOwnCert[_id];

        emit DeleteCertificate(
            _id,
            certificate.name,
            certificate.verifiedAt,
            ownerAddress
        );
    }
}
