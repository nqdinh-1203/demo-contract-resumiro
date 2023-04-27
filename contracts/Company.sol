// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IUser.sol";
import "../interfaces/ICompany.sol";
import "./library/UintArray.sol";

contract Company is ICompany {
    //=============================ATTRIBUTES==========================================
    uint[] allCopanyIds;
    mapping(uint => AppCompany) companies;
    mapping(address => mapping(uint => bool)) recruitersInCompany;
    mapping(uint => mapping(address => bool)) companiesConnectedRecruiter;
    IUser user;
    uint companyCounter = 0;

    constructor(address _userContract) {
        user = IUser(_userContract);
    }

    //=============================EVENTS==========================================
    event AddCompany(
        uint id,
        string name,
        string website,
        string location,
        string address_company
    );
    event UpdateCompany(
        uint id,
        string name,
        string website,
        string location,
        string address_company
    );
    event DeleteCompany(
        uint id,
        string name,
        string website,
        string location,
        string address_company
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
    error Company__NotExisted(uint company_id);
    error Company__AlreadyExisted(uint company_id);

    error RecruiterCompany__AlreadyIn(
        uint company_id,
        address recruiter_address
    );
    error RecruiterCompany__NotIn(uint company_id, address recruiter_address);

    error Recruiter__NotExisted(address user_address);

    //=============================METHODS==========================================
    //================COMPANIES=====================
    function _getCompany(uint _id) internal view returns (AppCompany memory) {
        return companies[_id];
    }

    function _getAllCompanies() internal view returns (AppCompany[] memory) {
        AppCompany[] memory arrCompany = new AppCompany[](allCopanyIds.length);

        for (uint i = 0; i < allCopanyIds.length; i++) {
            arrCompany[i] = companies[allCopanyIds[i]];
        }

        return arrCompany;
    }

    // only admin -> later⏳
    // company must not existed -> done✅
    function _addCompany(
        uint _id,
        string memory _name,
        string memory _website,
        string memory _location,
        string memory _addr
    ) internal {
        if (companies[_id].exist) {
            revert Company__AlreadyExisted({company_id: _id});
        }

        companies[_id] = AppCompany(
            allCopanyIds.length,
            _id,
            _name,
            _website,
            _location,
            _addr,
            true
        );
        allCopanyIds.push(_id);

        AppCompany memory company = _getCompany(_id);

        emit AddCompany(
            _id,
            company.name,
            company.website,
            company.location,
            company.addr
        );
    }

    // only admin -> later⏳
    // company must existed -> done✅
    function _updateCompany(
        uint _id,
        string memory _name,
        string memory _website,
        string memory _location,
        string memory _addr
    ) internal {
        if (!companies[_id].exist) {
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
            company.addr
        );
    }

    // only admin -> later⏳
    // company must existed -> done✅
    function _deleteCompany(uint _id) internal {
        if (!companies[_id].exist) {
            revert Company__NotExisted({company_id: _id});
        }

        AppCompany memory company = _getCompany(_id);

        uint lastIndex = allCopanyIds.length - 1;
        companies[allCopanyIds[lastIndex]].index = companies[_id].index;
        UintArray.remove(allCopanyIds, companies[_id].index);

        delete companies[_id];

        emit DeleteCompany(
            _id,
            company.name,
            company.website,
            company.location,
            company.addr
        );
    }

    function _isExistedCompanyRecruiter(
        address _recruiterAddress,
        uint _companyId
    ) internal view returns (bool) {
        return recruitersInCompany[_recruiterAddress][_companyId];
    }

    //========================COMPANY-RECRUITER=================================
    // only recruiter -> later⏳
    // param _recruiterAddress must equal msg.sender -> later⏳
    // company must existed -> done✅
    // just for recruiter in user contract -> done✅
    // recruiter must not in company -> done✅
    function _connectCompanyRecruiter(
        address _recruiterAddress,
        uint _companyId
    ) internal {
        if (!companies[_companyId].exist) {
            revert Company__NotExisted({company_id: _companyId});
        }
        if (
            !(user.isExisted(_recruiterAddress) &&
                user.hasType(_recruiterAddress, 1))
        ) {
            revert Recruiter__NotExisted({user_address: _recruiterAddress});
        }
        if (_isExistedCompanyRecruiter(_recruiterAddress, _companyId)) {
            revert RecruiterCompany__AlreadyIn({
                recruiter_address: _recruiterAddress,
                company_id: _companyId
            });
        }

        recruitersInCompany[_recruiterAddress][_companyId] = true;
        companiesConnectedRecruiter[_companyId][_recruiterAddress] = true;
        bool isIn = recruitersInCompany[_recruiterAddress][_companyId];

        emit ConnectCompanyRecruiter(_recruiterAddress, _companyId, isIn);
    }

    // only recruiter -> later⏳
    // param _recruiterAddress must equal msg.sender -> later⏳
    // company must existed -> done✅
    // just for recruiter in user contract -> done✅
    // recruiter must not in company -> done✅
    function _disconnectCompanyRecruiter(
        address _recruiterAddress,
        uint _companyId
    ) internal {
        if (!companies[_companyId].exist) {
            revert Company__NotExisted({company_id: _companyId});
        }
        if (
            !(user.isExisted(_recruiterAddress) &&
                user.hasType(_recruiterAddress, 1))
        ) {
            revert Recruiter__NotExisted({user_address: _recruiterAddress});
        }
        if (!_isExistedCompanyRecruiter(_recruiterAddress, _companyId)) {
            revert RecruiterCompany__NotIn({
                recruiter_address: _recruiterAddress,
                company_id: _companyId
            });
        }

        recruitersInCompany[msg.sender][_companyId] = false;
        companiesConnectedRecruiter[_companyId][_recruiterAddress] = false;
        bool isIn = recruitersInCompany[_recruiterAddress][_companyId];

        emit DisconnectCompanyRecruiter(msg.sender, _companyId, isIn);
    }

    function _getAllCompaniesConnectedRecruiter(
        address _recruiterAddress
    ) internal view returns (AppCompany[] memory) {
        AppCompany[] memory arrCompanies = new AppCompany[](
            allCopanyIds.length
        );

        for (uint i = 0; i < allCopanyIds.length; i++) {
            if (recruitersInCompany[_recruiterAddress][allCopanyIds[i]]) {
                arrCompanies[i] = companies[allCopanyIds[i]];
            }
        }

        return arrCompanies;
    }

    function _getAllRecruitersConnectedCompany(
        uint _companyId
    ) internal view returns (IUser.AppUser[] memory) {
        IUser.AppUser[] memory arrUsers = user.getAllRecruiters();
        IUser.AppUser[] memory arrRecruiters = new IUser.AppUser[](
            arrUsers.length
        );

        for (uint i = 0; i < arrUsers.length; i++) {
            if (
                arrUsers[i].exist &&
                companiesConnectedRecruiter[_companyId][
                    arrUsers[i].accountAddress
                ]
            ) {
                arrRecruiters[i] = arrUsers[i];
            }
        }

        return arrRecruiters;
    }

    //========================FOR INTERFACE=================================
    function isExistedCompanyRecruiter(
        address _recruiterAddress,
        uint _companyId
    ) external view returns (bool) {
        return _isExistedCompanyRecruiter(_recruiterAddress, _companyId);
    }

    function isExistedCompany(uint _id) external view returns (bool) {
        return companies[_id].exist;
    }

    function getCompany(uint _id) external view returns (AppCompany memory) {
        return _getCompany(_id);
    }

    function getAllCompanies() external view returns (AppCompany[] memory) {
        return _getAllCompanies();
    }

    function addCompany(
        uint _id,
        string memory _name,
        string memory _website,
        string memory _location,
        string memory _addr
    ) external {
        _addCompany(_id, _name, _website, _location, _addr);
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
