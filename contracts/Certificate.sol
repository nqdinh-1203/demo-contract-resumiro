// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IUser.sol";
import "../interfaces/ICertificate.sol";
import "./library/StringArray.sol";
import "./library/EnumrableSet.sol";

contract Certificate is ICertificate {
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant CANDIDATE_ROLE = keccak256("CANDIDATE_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    //=============================ATTRIBUTES==========================================
    uint certCounter = 1;
    EnumerableSet.UintSet certIds;
    mapping(uint => AppCertificate) certs;

    IUser user;
    constructor(address _userContract) {
        user = IUser(_userContract);
    }

    //=============================EVENTS==========================================
    event AddCertificate(
        uint id,
        string name,
        uint verified_at,
        address indexed owner_address,
        address indexed verifier_address,
        DocStatus status
    );
    event UpdateCertificate(
        uint id,
        string name,
        address indexed owner_address
    );
    event ChangeCertificateStatus(
        uint id,
        address indexed verifier_address,
        uint verified_at,
        DocStatus status
    );
    event DeleteCertificate(
        uint id,
        string name,
        uint verified_at,
        address indexed owner_address,
        address indexed verifier_address,
        DocStatus status
    );

    //=============================ERRORS==========================================
    error Cert__NotExisted(uint id);
    error Cert__AlreadyExisted(uint id);
    error Cert__Rejected(uint id);
    error Cert__NotPending(uint id);

    error Cert_Candidate__NotOwned(uint id, address candidate_address);
    error Cert_Verifier__NotVerifierOfCertificate(
        uint id,
        address verifier_address
    );

    error Candidate__NotExisted(address user_address);

    error Verifier__NotExisted(address user_address);

    error User__NoRole(address account);

    //=============================METHODs==========================================
    //==================CERTIFICATES=======================
    modifier onlyRole(bytes32 _role) {
        if (!user.hasRole(tx.origin, _role)) {
            revert User__NoRole({account: tx.origin});
        }
        _;
    }

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

    // only candidate -> later⏳ -> done✅
    // param _candidateAddress must equal msg.sender -> later⏳ -> done✅
    // id must not existed -> done✅
    // just add for candidate -> done✅
    // new ⭐ -> change params and event
    function _addCertificate (
        string memory _name,
        // uint _verifiedAt, -> not need to add
        address _candidateAddress,
        address _verifierAddress,
        string memory _certificateAddress
    ) internal onlyRole(CANDIDATE_ROLE) {
        if (_candidateAddress != tx.origin) {
            revert("param and call not match");
        }

        uint _id = certCounter;
        certCounter++;

        if (certIds.contains(_id)) {
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
            0, // 0 is not verified
            _certificateAddress,
            _candidateAddress,
            _verifierAddress,
            DocStatus.Pending
        );

        AppCertificate memory cert = certs[_id];
        certIds.add(_id);

        emit AddCertificate(
            _id,
            cert.name, 
            cert.verifiedAt, 
            cert.candidate,
            cert.verifier,
            cert.status
        );
    }

    // only candidate -> later⏳ -> done✅
    // candidate must own certificate -> later⏳ -> done✅
    // cannot update rejected or verified cert -> done✅
    // id must existed -> done✅
    // new ⭐ -> change params and event
    function _updateCertificate(
        uint _id,
        // uint _verifiedAt, -> not need to update
        string memory _name, // update this
        address _verifierAddress,
        string memory _certificateAddress
        // DocStatus _status -> candidate cannot change cert status 
    ) internal onlyRole(CANDIDATE_ROLE) {
        if (!_isOwnerOfCertificate(tx.origin, _id)) {
            revert Cert_Candidate__NotOwned({
                id: _id,
                candidate_address: tx.origin
            });
        }
        if (!certIds.contains(_id)) {
            revert Cert__NotExisted({id: _id});
        }
        if (certs[_id].status != DocStatus.Pending) {
            revert Cert__NotPending({id: _id});
        }

        // if (!_isVerifierOfCertificate(_verifierAddress, _id)) {
        //     revert Cert_Verifier__NotVerifierOfCertificate({
        //         id: _id,
        //         verifier_address: _verifierAddress
        //     });
        // }

        certs[_id].name = _name;
        certs[_id].verifier = _verifierAddress;
        certs[_id].certificateAddress = _certificateAddress;

        AppCertificate memory cert = certs[_id];

        // for (uint i = 0; i < appCerts.length; i++) {
        //     if (
        //         StringArray.equal(
        //             _certificateAddress,
        //             appCerts[i].certificateAddress
        //         )
        //     ) {
        //         delete appCerts[i];
        //         appCerts.push(cert);
        //         break;
        //     }
        // }

        // address candidateAddress = certs[_id].candidate;

        emit UpdateCertificate(
            _id,
            cert.name,
            cert.candidate
        );
    }

    // only verifier -> done✅
    // id must existed -> done✅
    // verifier must be setted for certificate -> done✅
    // cannot change status with rejected 
    // new ⭐
    function _changeCertificateStatus(uint _id, uint _status, uint _verifiedAt) internal onlyRole(VERIFIER_ROLE) {
        if (!certIds.contains(_id)) {
            revert Cert__NotExisted({id: _id});
        }

        if (!_isVerifierOfCertificate(tx.origin, _id)) {
            revert Cert_Verifier__NotVerifierOfCertificate({
                id: _id,
                verifier_address: tx.origin
            });
        }

        if (certs[_id].status == DocStatus.Rejected) {
            revert Cert__Rejected({
                id: _id
            });
        }

        certs[_id].status = DocStatus(_status);
        if (certs[_id].status == DocStatus.Verified) {
            certs[_id].verifiedAt = _verifiedAt;
        }
        
        AppCertificate memory cert = certs[_id];

        emit ChangeCertificateStatus(
            _id,
            cert.verifier,
            cert.verifiedAt,
            cert.status
        );
    }

    // only candidate -> later⏳ -> done✅
    // candidate must own certificate -> later⏳ -> done✅
    // id must not existed -> done✅
    // new ⭐ -> change event
    function _deleteCertificate(uint _id) internal onlyRole(CANDIDATE_ROLE) {
        if (!certIds.contains(_id)) {
            revert Cert__NotExisted({id: _id});
        }
        if (!_isOwnerOfCertificate(tx.origin, _id)) {
            revert Cert_Candidate__NotOwned({
                id: _id,
                candidate_address: tx.origin
            });
        }

        AppCertificate memory certificate = certs[_id];

        delete certs[_id];
        certIds.remove(_id);

        emit DeleteCertificate(
            _id,
            certificate.name,
            certificate.verifiedAt,
            certificate.candidate,
            certificate.verifier,
            certificate.status
        );
    }

    // new ⭐ -> change return
    function _getCertificate(
        string memory _certificateAddress
        // uint _id
    )
        internal
        view
        returns (
            AppCertificate memory cert
        )
    {
        for (uint i = 0; i < certIds.length(); i++) {
            if (StringArray.equal(certs[certIds.at(i)].certificateAddress, _certificateAddress)) {
                cert = certs[certIds.at(i)];
                break;
            }
        }

        // cert = certs[_id];
    }

    //   function getDocument(uint _id) public view
    //     returns (string memory name, address requester, address verifier, uint verifiedAt, DocStatus status) {
    //         AppCertificate memory cert = certs[_id];
    //     return (cert.name, cert.candidate, cert.verifier, cert.verifiedAt, cert.status);
    //   }

    // function getCount(address _addressUser) external view returns (uint) {
    //     return certCount[_addressUser];
    // }

    // only verifier -> done✅
    // new ⭐ -> change return
    function _getCertificateVerifier(
        address _verifierAddress
    )
        internal
        view
        onlyRole(VERIFIER_ROLE)
        returns (
            AppCertificate[] memory certArr
        )
    {
        certArr = new AppCertificate[](certIds.length());

        if (_verifierAddress != tx.origin) {
            revert("param and origin not match");
        }
        for (uint i = 0; i < certIds.length(); i++) {
            if (certs[certIds.at(i)].verifier == _verifierAddress) {
                certArr[i] = certs[certIds.at(i)];
            }
        }
    }

    // only candidate -> done✅
    // new ⭐ -> change return
    function _getCertificateCandidate(
        address _candidateAddress
    )
        internal
        view
        onlyRole(CANDIDATE_ROLE)
        returns (
            AppCertificate[] memory certArr
        )
    {
        certArr = new AppCertificate[](certIds.length());

        if (_candidateAddress != tx.origin) {
            revert("param and origin not match");
        }
        for (uint i = 0; i < certIds.length(); i++) {
            if (certs[certIds.at(i)].candidate == _candidateAddress) {
                certArr[i] = certs[certIds.at(i)];
            }
        }
    }

    //====================================FOR INTERFACE====================================
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

    function addCertificate(
        string memory _name,
        address _candidateAddress,
        address _verifierAddress,
        string memory _certificateAddress
    ) external {
        _addCertificate(_name, _candidateAddress, _verifierAddress, _certificateAddress);
    }

    function updateCertificate(
        uint _id,
        string memory _name,
        address _verifierAddress,
        string memory _certificateAddress
    ) external {
        _updateCertificate(_id, _name, _verifierAddress, _certificateAddress);
    }

    function changeCertificateStatus(uint _id, uint _status, uint _verifiedAt) external {
        _changeCertificateStatus(_id, _status, _verifiedAt);
    }

    function deleteCertificate(uint _id) external onlyRole(CANDIDATE_ROLE) {
        _deleteCertificate(_id);
    }

    function getCertificate(
        string memory _certificateAddress
        // uint _id
    )
        external
        view
        returns (
            AppCertificate memory
        )
    {
        return _getCertificate(_certificateAddress);
    }

    function getCertificateVerifier(
        address _verifierAddress
    )
        external
        view
        onlyRole(VERIFIER_ROLE)
        returns (
            AppCertificate[] memory
        )
    {
        return _getCertificateVerifier(_verifierAddress);
    }

    function getCertificateCandidate(
        address _candidateAddress
    )
        external
        view
        returns (AppCertificate[] memory)
    {
        return _getCertificateCandidate(_candidateAddress);
    }


    //====================================USER CONTRACT====================================
    function setUserInterface(address _contract) public {
        user = IUser(_contract);
    }
}
