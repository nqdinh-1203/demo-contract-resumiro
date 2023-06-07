// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IUser.sol";
import "../interfaces/ICertificate.sol";
import "./library/StringArray.sol";

contract Certificate is ICertificate {
    //=============================ATTRIBUTES==========================================
    uint certCounter = 1;
    mapping(address => uint) certCount;
    mapping(uint => AppCertificate) certs;
    AppCertificate[] appCerts;

    IUser user;

    constructor(address _userContract) {
        user = IUser(_userContract);
    }

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
    error Cert__NotExisted(uint id);
    error Cert__AlreadyExisted(uint id);

    error Cert_Candidate__NotOwned(uint id, address candidate_address);
    error Cert_Verifier__NotVerifierOfCertificate(
        uint id,
        address verifier_address
    );

    error Candidate__NotExisted(address user_address);

    error Verifier__NotExisted(address user_address);

    //=============================METHODs==========================================
    //==================CERTIFICATES=======================
    function _isOwnerOfCertificate(
        address _candidateAddress,
        uint _id
    ) internal view returns (bool) {
        return certs[_id].candidate == _candidateAddress;
    }

    function _isVerifierOfCertificate(
        address _verifierAddress,
        uint _id
    ) internal view returns (bool) {
        return certs[_id].verifier == _verifierAddress;
    }

    function isOwnerOfCertificate(
        address _candidateAddress,
        uint _id
    ) external view returns (bool) {
        return _isOwnerOfCertificate(_candidateAddress, _id);
    }

    function isVerifierOfCertificate(
        address _verifierAddress,
        uint _id
    ) external view returns (bool) {
        return _isVerifierOfCertificate(_verifierAddress, _id);
    }

    // only candidate -> later⏳
    // param _candidateAddress must equal msg.sender -> later⏳
    // id must not existed -> done✅
    // just add for candidate -> done✅
    function addCertificate(
        // uint _id,
        string memory _name,
        uint _verifiedAt,
        address _candidateAddress,
        address _verifierAddress,
        string memory _certificateAddress
    ) external {
        uint _id = certCounter;
        certCounter++;

        if (certs[_id].exist) {
            revert Cert__AlreadyExisted({id: _id});
        }
        if (
            !(user.isExisted(_candidateAddress) &&
                user.hasType(_candidateAddress, 0))
        ) {
            revert Candidate__NotExisted({user_address: _candidateAddress});
        }
        if (
            !(user.isExisted(_verifierAddress) &&
                user.hasType(_verifierAddress, 2))
        ) {
            revert Verifier__NotExisted({user_address: _verifierAddress});
        }

        certs[_id] = AppCertificate(
            _name,
            _verifiedAt,
            true,
            _certificateAddress,
            _candidateAddress,
            _verifierAddress,
            DocStatus.Pending
        );

        certCount[_candidateAddress] += 1;
        certCount[_verifierAddress] += 1;

        AppCertificate memory cert = certs[_id];

        appCerts.push(cert);

        emit AddCertificate(_id, cert.name, cert.verifiedAt, _candidateAddress);
    }

    // only candidate -> later⏳
    // candidate must own certificate -> later⏳
    // id must not existed -> done✅
    function updateCertificate(
        uint _id,
        uint _verifiedAt,
        address _verifierAddress,
        string memory _certificateAddress,
        DocStatus _status
    ) external {
        if (!certs[_id].exist) {
            revert Cert__NotExisted({id: _id});
        }

        if (!_isVerifierOfCertificate(_verifierAddress, _id)) {
            revert Cert_Verifier__NotVerifierOfCertificate({
                id: _id,
                verifier_address: _verifierAddress
            });
        }

        certs[_id].verifiedAt = _verifiedAt;
        certs[_id].status = _status;
        AppCertificate memory cert = certs[_id];

        for (uint i = 0; i < appCerts.length; i++) {
            if (
                StringArray.equal(
                    _certificateAddress,
                    appCerts[i].certificateAddress
                )
            ) {
                delete appCerts[i];
                appCerts.push(cert);
                break;
            }
        }

        address candidateAddress = certs[_id].candidate;

        emit UpdateCertificate(
            _id,
            cert.name,
            cert.verifiedAt,
            candidateAddress
        );
    }

    // only candidate -> later⏳
    // candidate must own certificate -> later⏳
    // id must not existed -> done✅
    function deleteCertificate(uint _id) external {
        if (!certs[_id].exist) {
            revert Cert__NotExisted({id: _id});
        }

        if (!_isOwnerOfCertificate(msg.sender, _id)) {
            revert Cert_Candidate__NotOwned({
                id: _id,
                candidate_address: msg.sender
            });
        }

        AppCertificate memory certificate = certs[_id];
        address ownerAddress = certs[_id].candidate;

        for (uint i = 0; i < appCerts.length; i++) {
            if (
                StringArray.equal(
                    certificate.certificateAddress,
                    appCerts[i].certificateAddress
                )
            ) {
                appCerts[i] = appCerts[appCerts.length - 1];
                appCerts.pop();
                break;
            }
        }

        certCount[certs[_id].candidate] -= 1;
        certCount[certs[_id].verifier] -= 1;

        delete certs[_id];

        emit DeleteCertificate(
            _id,
            certificate.name,
            certificate.verifiedAt,
            ownerAddress
        );
    }

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
        )
    {
        uint index = 0;
        AppCertificate memory cert = certs[index];
        while (cert.candidate != address(0)) {
            if (
                StringArray.equal(cert.certificateAddress, _certificateAddress)
            ) {
                break;
            } else {
                index += 1;
                cert = certs[index];
            }
        }
        return (
            cert.name,
            cert.candidate,
            cert.verifier,
            cert.verifiedAt,
            cert.status
        );
    }

    //   function getDocument(uint _id) public view
    //     returns (string memory name, address requester, address verifier, uint verifiedAt, DocStatus status) {
    //         AppCertificate memory cert = certs[_id];
    //     return (cert.name, cert.candidate, cert.verifier, cert.verifiedAt, cert.status);
    //   }

    function getCount(address _addressUser) external view returns (uint) {
        return certCount[_addressUser];
    }

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
        )
    {
        for (uint i = lindex; i < appCerts.length; i++) {
            if (appCerts[i].verifier == _verifierAddress) {
                name = appCerts[i].name;
                verifiedAt = appCerts[i].verifiedAt;
                certificateAddress = appCerts[i].certificateAddress;
                candidate = appCerts[i].candidate;
                status = appCerts[i].status;
                index = i;
                break;
            }
        }
        return (name, candidate, verifiedAt, certificateAddress, status, index);
    }

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
        )
    {
        for (uint i = lindex; i < appCerts.length; i++) {
            if (appCerts[i].candidate == _candidateAddress) {
                name = appCerts[i].name;
                verifiedAt = appCerts[i].verifiedAt;
                certificateAddress = appCerts[i].certificateAddress;
                verifier = appCerts[i].verifier;
                status = appCerts[i].status;
                index = i;
                break;
            }
        }
        return (name, verifier, verifiedAt, certificateAddress, status, index);
    }

    //======================USER CONTRACT==========================
    function setUserInterface(address _contract) public {
        user = IUser(_contract);
    }
}
