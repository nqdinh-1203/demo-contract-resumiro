// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IUser.sol";
import "../interfaces/ICompany.sol";
import "./library/UintArray.sol";
import "./library/EnumrableSet.sol";

contract Company is ICompany {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant ADMIN_ROLE = 0x00;
    bytes32 public constant CANDIDATE_ROLE = keccak256("CANDIDATE_ROLE");
    bytes32 public constant RECRUITER_ROLE = keccak256("RECRUITER_ROLE");

    //=============================ATTRIBUTES==========================================
    EnumerableSet.UintSet companyIds;
    uint companyCounter = 1;
    mapping(uint => AppCompany) companies;
    mapping(address => EnumerableSet.UintSet) recruitersInCompany;
    // mapping(uint => EnumerableSet.AddressSet) companiesConnectedRecruiter;
    IUser user;

    constructor(address _userContract) {
        user = IUser(_userContract);
    }

    //=============================EVENTS==========================================
    event AddCompany(
        uint id,
        string name,
        string website,
        string location,
        string address_company,
        address indexed creater
    );
    event UpdateCompany(
        uint id,
        string name,
        string website,
        string location,
        string address_company,
        address indexed creater
    );
    event DeleteCompany(
        uint id,
        string name,
        string website,
        string location,
        string address_company,
        address indexed creater
    );
    event ConnectCompanyRecruiter(
        address indexed recruiter_address,
        uint company_id,
        bool isConnect
    );
    event DisconnectCompanyRecruiter(
        address indexed recruiter_address,
        uint company_id,
        bool isConnect
    );

    //=============================ERRORS==========================================
    error User__NoRole(address account);

    error Company__NotExisted(uint company_id);
    error Company__AlreadyExisted(uint company_id);
    error NotCreater(address account, uint company_id);

    error RecruiterCompany__AlreadyIn(
        uint company_id,
        address recruiter_address
    );
    error RecruiterCompany__NotIn(uint company_id, address recruiter_address);

    error Recruiter__NotExisted(address user_address);

    //=============================METHODS==========================================
    //================COMPANIES=====================
    modifier onlyRole(bytes32 _role) {
        if (!user.hasRole(tx.origin, _role)) {
            revert User__NoRole({account: tx.origin});
        }
        _;
    }

    modifier onlyCreater(uint _id) {
        AppCompany memory company = _getCompany(_id);
        if (company.creater != tx.origin) {
            revert NotCreater({account: tx.origin, company_id: _id});
        }
        _;
    }

    function _getCompany(uint _id) internal view returns (AppCompany memory) {
        return companies[_id];
    }

    function _getAllCompanies() internal view returns (AppCompany[] memory) {
        AppCompany[] memory arrCompany = new AppCompany[](companyIds.length());

        for (uint i = 0; i < companyIds.length(); i++) {
            arrCompany[i] = companies[companyIds.at(i)];
        }

        return arrCompany;
    }

    // only admin -> later⏳ -> done✅
    // company must not existed -> done✅
    function _addCompany(
        string memory _name,
        string memory _website,
        string memory _location,
        string memory _addr
    ) internal onlyRole(ADMIN_ROLE) {
        uint _id = companyCounter;
        companyCounter++;

        if (companyIds.contains(_id)) {
            revert Company__AlreadyExisted({company_id: _id});
        }

        companies[_id] = AppCompany(
            _id,
            _name,
            _website,
            _location,
            _addr,
            tx.origin
        );
        companyIds.add(_id);

        AppCompany memory company = _getCompany(_id);

        emit AddCompany(
            _id,
            company.name,
            company.website,
            company.location,
            company.addr,
            tx.origin
        );
    }

    // only admin -> later⏳ -> done✅
    // company must existed -> done✅
    function _updateCompany(
        uint _id,
        string memory _name,
        string memory _website,
        string memory _location,
        string memory _addr
    ) internal onlyRole(ADMIN_ROLE) onlyCreater(_id) {
        if (!companyIds.contains(_id)) {
            revert Company__NotExisted({company_id: _id});
        }

        companies[_id].name = _name;
        companies[_id].website = _website;
        companies[_id].location = _location;
        companies[_id].addr = _addr;

        AppCompany memory company = _getCompany(_id);

        emit UpdateCompany(
            _id,
            company.name,
            company.website,
            company.location,
            company.addr,
            tx.origin
        );
    }

    // only admin -> later⏳ -> done✅
    // company must existed -> done✅
    function _deleteCompany(
        uint _id
    ) internal onlyRole(ADMIN_ROLE) onlyCreater(_id) {
        if (!companyIds.contains(_id)) {
            revert Company__NotExisted({company_id: _id});
        }

        AppCompany memory company = _getCompany(_id);

        companyIds.remove(_id);
        delete companies[_id];

        emit DeleteCompany(
            _id,
            company.name,
            company.website,
            company.location,
            company.addr,
            tx.origin
        );
    }

    function _isExistedCompanyRecruiter(
        address _recruiterAddress,
        uint _companyId
    ) internal view returns (bool) {
        return recruitersInCompany[_recruiterAddress].contains(_companyId);
    }

    //========================COMPANY-RECRUITER=================================
    // only recruiter -> later⏳ -> done✅
    // param _recruiterAddress must equal msg.sender -> later⏳
    // company must existed -> done✅
    // just for recruiter in user contract -> done✅
    // recruiter must not in company -> done✅
    function _connectCompanyRecruiter(
        address _recruiterAddress,
        uint _companyId
    ) internal onlyRole(RECRUITER_ROLE) {
        if (tx.origin != _recruiterAddress) {
            revert("param and call not match");
        }
        if (!companyIds.contains(_companyId)) {
            revert Company__NotExisted({company_id: _companyId});
        }
        if (
            !((user.isExisted(_recruiterAddress) &&
                user.hasType(_recruiterAddress, 1)) ||
                user.hasType(_recruiterAddress, 2))
        ) {
            revert Recruiter__NotExisted({user_address: _recruiterAddress});
        }
        if (_isExistedCompanyRecruiter(_recruiterAddress, _companyId)) {
            revert RecruiterCompany__AlreadyIn({
                recruiter_address: _recruiterAddress,
                company_id: _companyId
            });
        }

        recruitersInCompany[_recruiterAddress].add(_companyId);
        bool isIn = recruitersInCompany[_recruiterAddress].contains(_companyId);

        emit ConnectCompanyRecruiter(_recruiterAddress, _companyId, isIn);
    }

    // only recruiter -> later⏳ -> done✅
    // param _recruiterAddress must equal msg.sender -> later⏳ -> done✅
    // company must existed -> done✅
    // just for recruiter in user contract -> done✅
    // recruiter must not in company -> done✅
    function _disconnectCompanyRecruiter(
        address _recruiterAddress,
        uint _companyId
    ) internal onlyRole(RECRUITER_ROLE) {
        if (tx.origin != _recruiterAddress) {
            revert("param and call not match");
        }

        if (!companyIds.contains(_companyId)) {
            revert Company__NotExisted({company_id: _companyId});
        }
        if (
            !((user.isExisted(_recruiterAddress) &&
                user.hasType(_recruiterAddress, 1)) ||
                user.hasType(_recruiterAddress, 2))
        ) {
            revert Recruiter__NotExisted({user_address: _recruiterAddress});
        }
        if (!_isExistedCompanyRecruiter(_recruiterAddress, _companyId)) {
            revert RecruiterCompany__NotIn({
                recruiter_address: _recruiterAddress,
                company_id: _companyId
            });
        }

        recruitersInCompany[_recruiterAddress].remove(_companyId);
        // companiesConnectedRecruiter[_companyId][_recruiterAddress] = false;
        bool isIn = recruitersInCompany[_recruiterAddress].contains(_companyId);

        emit DisconnectCompanyRecruiter(msg.sender, _companyId, isIn);
    }

    function _getAllCompaniesConnectedRecruiter(
        address _recruiterAddress
    ) internal view returns (AppCompany[] memory) {
        AppCompany[] memory companyArr = new AppCompany[](
            recruitersInCompany[_recruiterAddress].length()
        );

        for (uint i = 0; i < companyIds.length(); i++) {
            companyArr[i] = companies[companyIds.at(i)];
        }

        return companyArr;
    }

    function _getAllRecruitersConnectedCompany(
        uint _companyId
    ) internal view returns (IUser.AppUser[] memory) {
        IUser.AppUser[] memory userArr = user.getAllRecruiters();
        IUser.AppUser[] memory recruiterArr = new IUser.AppUser[](
            userArr.length
        );

        for (uint i = 0; i < userArr.length; i++) {
            if (
                user.isExisted(userArr[i].accountAddress) &&
                recruitersInCompany[userArr[i].accountAddress].contains(
                    _companyId
                )
            ) {
                recruiterArr[i] = userArr[i];
            }
        }

        return recruiterArr;
    }

    //========================FOR INTERFACE=================================
    function isExistedCompanyRecruiter(
        address _recruiterAddress,
        uint _companyId
    ) external view returns (bool) {
        return _isExistedCompanyRecruiter(_recruiterAddress, _companyId);
    }

    function isExistedCompany(uint _id) external view returns (bool) {
        return companyIds.contains(_id);
    }

    function getCompany(uint _id) external view returns (AppCompany memory) {
        return _getCompany(_id);
    }

    function getAllCompanies() external view returns (AppCompany[] memory) {
        return _getAllCompanies();
    }

    function getLatestCompanyId() external view returns (uint) {
        return companyCounter - 1;
    }

    function addCompany(
        string memory _name,
        string memory _website,
        string memory _location,
        string memory _addr
    ) external {
        _addCompany(_name, _website, _location, _addr);
    }

    function updateCompany(
        uint _id,
        string memory _name,
        string memory _website,
        string memory _location,
        string memory _addr
    ) external {
        _updateCompany(_id, _name, _website, _location, _addr);
    }

    function deleteCompany(uint _id) external {
        _deleteCompany(_id);
    }

    function connectCompanyRecruiter(
        address _recruiterAddress,
        uint _companyId
    ) external {
        _connectCompanyRecruiter(_recruiterAddress, _companyId);
    }

    function disconnectCompanyRecruiter(
        address _recruiterAddress,
        uint _companyId
    ) external {
        _disconnectCompanyRecruiter(_recruiterAddress, _companyId);
    }

    function getAllCompaniesConnectedRecruiter(
        address _recruiterAddress
    ) external view returns (AppCompany[] memory) {
        return _getAllCompaniesConnectedRecruiter(_recruiterAddress);
    }

    function getAllRecruitersConnectedCompany(
        uint _companyId
    ) external view returns (IUser.AppUser[] memory) {
        return _getAllRecruitersConnectedCompany(_companyId);
    }

    //======================INTERFACES==========================
    function setUserInterface(address _contract) public {
        user = IUser(_contract);
    }
}
