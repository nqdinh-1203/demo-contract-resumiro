// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IUser.sol";
import "../interfaces/ICompany.sol";
import "../interfaces/ICertificate.sol";
import "./library/StringArray.sol";
import "./library/EnumrableSet.sol";

contract Certificate is ICertificate {
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant ADMIN = 0x00;
    bytes32 public constant CANDIDATE_ROLE = keccak256("CANDIDATE_ROLE");
    bytes32 public constant ADMIN_COMPANY_ROLE =
        keccak256("ADMIN_COMPANY_ROLE");

    //=============================[ATTRIBUTES]==========================================
    uint certCounter = 1;
    EnumerableSet.UintSet certIds;
    mapping(uint => AppCertificate) certs;

    IUser user;
    ICompany company;

    constructor(address _userContract, address _companyContract) {
        user = IUser(_userContract);
        company = ICompany(_companyContract);
    }

    //=============================[EVENTS]==========================================
    event AddCertificate(
        uint id,
        string name,
        uint expired_at,
        address indexed owner_address,
        address indexed verifier_address,
        uint company_id,
        CertStatus status
    );
    event UpdateCertificate(
        uint id,
        string name,
        address indexed owner_address,
        uint company_id
    );
    event ChangeCertificateStatus(
        uint id,
        address indexed verifier_address,
        uint company_id,
        uint expired_at,
        CertStatus status
    );
    event DeleteCertificate(
        uint id,
        string name,
        uint expired_at,
        address indexed owner_address,
        address indexed verifier_address,
        uint company_id,
        CertStatus status
    );

    //=============================[ERRORS]==========================================
    error Cert__NotExisted(uint id);
    error Cert__AlreadyExisted(uint id);
    error Cert__Rejected(uint id);
    error Cert__NotPending(uint id);

    error Cert_Candidate__NotOwned(uint cert_id, address candidate_address);
    error Cert_Candidate__NotForSelf(
        address candidate_address,
        address origin_address
    );
    error Cert_Verifier__NotVerifierOfCertificate(
        uint cert_id,
        address verifier_address
    );

    error Candidate__NotExisted(address user_address);

    error Verifier__NotExisted(address user_address);
    error Verifier__NotCreator(uint company_id, address verifier_address);

    error User__NoRole(address account);

    //=============================[METHODs]==========================================
    //==================[MODIFIERs]=======================
    modifier onlyRole(bytes32 _role) {
        if (!user.hasRole(tx.origin, _role)) {
            revert User__NoRole({account: tx.origin});
        }
        _;
    }

    modifier onlyOwner(uint _id) {
        if (certs[_id].candidate != tx.origin) {
            revert Cert_Candidate__NotOwned({
                cert_id: _id,
                candidate_address: tx.origin
            });
        }
        _;
    }

    modifier onlySelf(address account) {
        if (account != tx.origin) {
            revert Cert_Candidate__NotForSelf({
                candidate_address: account,
                origin_address: tx.origin
            });
        }
        _;
    }

    //==================[CERTIFICATES]=======================
    function _isOwnerOfCertificate(
        address _candidateAddress,
        uint _id
    ) public view returns (bool) {
        return certs[_id].candidate == _candidateAddress;
    }

    function _isVerifierOfCertificate(
        address _verifierAddress,
        uint _id
    ) internal view returns (bool) {
        return certs[_id].verifier == _verifierAddress;
    }

    /**
     * only candidate -> later⏳ -> done✅
     * param _candidateAddress must equal msg.sender -> later⏳ -> done✅ -> onlySelf
     * id must not existed -> done✅
     * just add for candidate -> done✅
     * new ⭐ -> change params and event
     */
    function _addCertificate(
        string memory _name,
        // uint _expiredAt, -> not need to add
        string memory _certificateAddress,
        address _candidateAddress,
        address _verifierAddress,
        uint _companyId
    ) internal onlyRole(CANDIDATE_ROLE) onlySelf(_candidateAddress) {
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
        if (!company.isCreator(_companyId, _verifierAddress)) {
            revert Verifier__NotCreator({
                company_id: _companyId,
                verifier_address: _verifierAddress
            });
        }

        certs[_id] = AppCertificate(
            _name,
            0, // 0 is not verified
            _certificateAddress,
            _candidateAddress,
            _verifierAddress,
            _companyId,
            CertStatus.Pending
        );

        AppCertificate memory cert = certs[_id];
        certIds.add(_id);

        emit AddCertificate(
            _id,
            cert.name,
            cert.expiredAt,
            cert.candidate,
            cert.verifier,
            cert.companyId,
            cert.status
        );
    }

    /**
     * only candidate -> later⏳ -> done✅
     * candidate must own certificate -> later⏳ -> done✅ -> onlyOwner
     * verifier is creator of company -> done✅
     * cannot update rejected or verified cert -> done✅
     * id must existed -> done✅
     * new ⭐ -> change params and event
     */
    function _updateCertificate(
        uint _id,
        // uint _expiredAt, -> not need to update
        string memory _name, // update this
        string memory _certificateAddress,
        address _verifierAddress,
        uint _companyId // -> add
    )
        internal
        // CertStatus _status -> candidate cannot change cert status
        onlyRole(CANDIDATE_ROLE)
        onlyOwner(_id)
    {
        if (!company.isCreator(_companyId, _verifierAddress)) {
            revert Verifier__NotCreator({
                company_id: _companyId,
                verifier_address: _verifierAddress
            });
        }
        if (!certIds.contains(_id)) {
            revert Cert__NotExisted({id: _id});
        }
        if (certs[_id].status != CertStatus.Pending) {
            revert Cert__NotPending({id: _id});
        }

        certs[_id].name = _name;
        certs[_id].verifier = _verifierAddress;
        certs[_id].certificateAddress = _certificateAddress;
        certs[_id].companyId = _companyId;

        AppCertificate memory cert = certs[_id];

        emit UpdateCertificate(_id, cert.name, cert.candidate, cert.companyId);
    }

    /**
     * only verifier -> done✅
     * id must existed -> done✅
     * verifier must be setted for certificate -> done✅
     * verifier is creator of company -> done✅
     * cannot change status with rejected -> done✅
     * new ⭐
     */
    function _changeCertificateStatus(
        uint _id,
        uint _status,
        uint _expiredAt
    ) internal onlyRole(ADMIN_COMPANY_ROLE) {
        if (!certIds.contains(_id)) {
            revert Cert__NotExisted({id: _id});
        }

        if (!_isVerifierOfCertificate(tx.origin, _id)) {
            revert Cert_Verifier__NotVerifierOfCertificate({
                cert_id: _id,
                verifier_address: tx.origin
            });
        }

        if (!company.isCreator(certs[_id].companyId, tx.origin)) {
            revert Verifier__NotCreator({
                company_id: certs[_id].companyId,
                verifier_address: tx.origin
            });
        }

        if (certs[_id].status == CertStatus.Rejected) {
            revert Cert__Rejected({id: _id});
        }

        certs[_id].status = CertStatus(_status);
        if (certs[_id].status == CertStatus.Verified) {
            certs[_id].expiredAt = _expiredAt;
        }

        AppCertificate memory cert = certs[_id];

        emit ChangeCertificateStatus(
            _id,
            cert.verifier,
            cert.companyId,
            cert.expiredAt,
            cert.status
        );
    }

    // only candidate -> later⏳ -> done✅
    // candidate must own certificate -> later⏳ -> done✅ -> onlyOwner
    // id must not existed -> done✅
    // new ⭐ -> change event
    function _deleteCertificate(
        uint _id
    ) internal onlyRole(CANDIDATE_ROLE) onlyOwner(_id) {
        if (!certIds.contains(_id)) {
            revert Cert__NotExisted({id: _id});
        }

        AppCertificate memory certificate = certs[_id];

        delete certs[_id];
        certIds.remove(_id);

        emit DeleteCertificate(
            _id,
            certificate.name,
            certificate.expiredAt,
            certificate.candidate,
            certificate.verifier,
            certificate.companyId,
            certificate.status
        );
    }

    // new ⭐ -> change return
    function _getCertificate(
        string memory _certificateAddress
    )
        internal
        view
        returns (
            // uint _id
            AppCertificate memory cert
        )
    {
        for (uint i = 0; i < certIds.length(); i++) {
            if (
                StringArray.equal(
                    certs[certIds.at(i)].certificateAddress,
                    _certificateAddress
                )
            ) {
                cert = certs[certIds.at(i)];
                break;
            }
        }

        // cert = certs[_id];
    }

    // only verifier -> done✅
    // new ⭐ -> change return
    function _getCertificateVerifier(
        address _verifierAddress
    )
        internal
        view
        onlyRole(ADMIN_COMPANY_ROLE)
        returns (AppCertificate[] memory certArr)
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
        returns (AppCertificate[] memory certArr)
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
        string memory _certificateAddress,
        address _candidateAddress,
        address _verifierAddress,
        uint _companyId
    ) external {
        _addCertificate(
            _name,
            _certificateAddress,
            _candidateAddress,
            _verifierAddress,
            _companyId
        );
    }

    function updateCertificate(
        uint _id,
        string memory _name,
        string memory _certificateAddress,
        address _verifierAddress,
        uint _companyId
    ) external {
        _updateCertificate(
            _id,
            _name,
            _certificateAddress,
            _verifierAddress,
            _companyId
        );
    }

    function changeCertificateStatus(
        uint _id,
        uint _status,
        uint _expiredAt
    ) external {
        _changeCertificateStatus(_id, _status, _expiredAt);
    }

    function deleteCertificate(uint _id) external {
        _deleteCertificate(_id);
    }

    function getCertificate(
        string memory _certificateAddress
    ) external view returns (AppCertificate memory) {
        return _getCertificate(_certificateAddress);
    }

    function getCertificateVerifier(
        address _verifierAddress
    ) external view returns (AppCertificate[] memory) {
        return _getCertificateVerifier(_verifierAddress);
    }

    function getCertificateCandidate(
        address _candidateAddress
    ) external view returns (AppCertificate[] memory) {
        return _getCertificateCandidate(_candidateAddress);
    }

    //====================================USER CONTRACT====================================
    function setUserInterface(address _contract) public onlyRole(ADMIN) {
        user = IUser(_contract);
    }

    function setCompanyInterface(address _contract) public onlyRole(ADMIN) {
        company = ICompany(_contract);
    }
}
