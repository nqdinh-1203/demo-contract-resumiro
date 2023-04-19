// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Certificate {
    struct AppCertificate {
        string name;
        uint verifiedAt;
        bool exist;
    }

    //=============================ATTRIBUTES==========================================
    mapping(uint => AppCertificate) certs;
    mapping(uint => address) candidateOwnCert;

    //=============================EVENTS==========================================
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

    //=============================ERRORS==========================================
    error NotExisted(uint id);
    error AlreadyExisted(uint id);
    error NotOwned(uint id, address candidate_address);

    //=============================METHODs==========================================
    //==================CERTIFICATES=======================
    function isOwnerOfCertificate(
        address _candidateAddress,
        uint _id
    ) public view returns (bool) {
        return candidateOwnCert[_id] == _candidateAddress;
    }

    // only candidate -> later
    // param _candidateAddress must equal msg.sender -> later
    // id must not existed
    function addCertificate(
        uint _id,
        string memory _name,
        uint _verifiedAt,
        address _candidateAddress
    ) public virtual {
        if (certs[_id].exist) {
            revert AlreadyExisted({id: _id});
        }

        certs[_id] = AppCertificate(_name, _verifiedAt, true);
        candidateOwnCert[_id] = _candidateAddress;

        AppCertificate memory cert = certs[_id];

        emit AddCertificate(_id, cert.name, cert.verifiedAt, _candidateAddress);
    }

    // only candidate -> later
    // candidate must own certificate
    // id must not existed
    function updateCertificate(
        uint _id,
        string memory _name,
        uint _verifiedAt
    ) public virtual {
        if (!certs[_id].exist) {
            revert NotExisted({id: _id});
        }

        if (isOwnerOfCertificate(msg.sender, _id)) {
            revert NotOwned({id: _id, candidate_address: msg.sender});
        }

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

    // only candidate -> later
    // candidate must own certificate
    // id must not existed
    function deleteCertificate(uint _id) public virtual {
        if (!certs[_id].exist) {
            revert NotExisted({id: _id});
        }

        if (isOwnerOfCertificate(msg.sender, _id)) {
            revert NotOwned({id: _id, candidate_address: msg.sender});
        }

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
