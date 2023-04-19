// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Company {
    struct AppCompany {
        string name;
        string website;
        string location;
        string addr;
        bool exist;
    }

    //=============================ATTRIBUTES==========================================
    mapping(uint => AppCompany) companies;
    mapping(address => mapping(uint => bool)) recruitersInCompany;

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
    error NotExistedCompany(uint company_id);
    error AlreadyExistedCompany(uint company_id);

    error RecruiterAlreadyInCompany(uint company_id, address recruiter_address);
    error RecruiterNotInCompany(uint company_id, address recruiter_address);

    //=============================METHODS==========================================
    //================COMPANIES=====================
    function getCompany(uint _id) public view returns (AppCompany memory) {
        return companies[_id];
    }

    // only admin -> later⏳
    // company must not existed -> done✅
    function addCompany(
        uint _id,
        string memory _name,
        string memory _website,
        string memory _location,
        string memory _addr
    ) public virtual {
        if (companies[_id].exist) {
            revert AlreadyExistedCompany({company_id: _id});
        }

        companies[_id] = AppCompany(_name, _website, _location, _addr, true);

        AppCompany memory company = getCompany(_id);

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
    function updateCompany(
        uint _id,
        string memory _name,
        string memory _website,
        string memory _location,
        string memory _addr
    ) public virtual {
        if (!companies[_id].exist) {
            revert NotExistedCompany({company_id: _id});
        }

        companies[_id].name = _name;
        companies[_id].website = _website;
        companies[_id].location = _location;
        companies[_id].addr = _addr;

        AppCompany memory company = getCompany(_id);

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
    function deleteCompany(uint _id) public virtual {
        if (!companies[_id].exist) {
            revert NotExistedCompany({company_id: _id});
        }

        AppCompany memory company = getCompany(_id);

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
    // recruiter must not in company -> done✅
    function connectCompanyRecruiter(
        address _recruiterAddress,
        uint _companyId
    ) public virtual {
        require(companies[_companyId].exist, "Company-Recruiter: ID not exist");
        require(
            !_isExistedCompanyRecruiter(_recruiterAddress, _companyId),
            "Company-Recruiter: Recruiter already connected with Company"
        );

        recruitersInCompany[_recruiterAddress][_companyId] = true;
        bool isIn = recruitersInCompany[_recruiterAddress][_companyId];

        emit ConnectCompanyRecruiter(_recruiterAddress, _companyId, isIn);
    }

    // only recruiter -> later⏳
    // param _recruiterAddress must equal msg.sender -> later⏳
    // company must existed -> done✅
    // recruiter must not in company -> done✅
    function disconnectCompanyRecruiter(
        address _recruiterAddress,
        uint _companyId
    ) public virtual {
        require(companies[_companyId].exist, "Company-Recruiter: ID not exist");
        require(
            _isExistedCompanyRecruiter(_recruiterAddress, _companyId),
            "Company-Recruiter: Recruiter not connect with Company"
        );

        recruitersInCompany[msg.sender][_companyId] = false;
        bool isIn = recruitersInCompany[_recruiterAddress][_companyId];

        emit DisconnectCompanyRecruiter(msg.sender, _companyId, isIn);
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
}
