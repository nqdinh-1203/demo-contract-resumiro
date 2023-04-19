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

    mapping(uint => AppCompany) companies;
    mapping(address => mapping(uint => bool)) recruitersInCompany;

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

    function getCompany(uint _id) public view returns (AppCompany memory) {
        return companies[_id];
    }

    // only admin -> resumiro
    // company must not existed
    function addCompany(
        uint _id,
        string memory _name,
        string memory _website,
        string memory _location,
        string memory _addr
    ) public virtual {
        require(!companies[_id].exist, "Company: id already existed");

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

    // only admin -> resumiro
    // company must existed
    function updateCompany(
        uint _id,
        string memory _name,
        string memory _website,
        string memory _location,
        string memory _addr
    ) public virtual {
        require(companies[_id].exist, "Company: ID not exist");

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

    // only admin -> resumiro
    // company must existed
    function deleteCompany(uint _id) public virtual {
        require(companies[_id].exist, "Company: ID not exist");
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

    function isExistedCompanyRecruiter(
        address _recruiterAddress,
        uint _companyId
    ) public view returns (bool) {
        return recruitersInCompany[_recruiterAddress][_companyId];
    }

    // only recruiter -> resumiro
    // param _recruiterAddress must equal msg.sender -> resmiro
    // company must existed
    // recruiter must not in company
    function connectCompanyRecruiter(
        address _recruiterAddress,
        uint _companyId
    ) public virtual {
        require(companies[_companyId].exist, "Company-Recruiter: ID not exist");
        require(
            !isExistedCompanyRecruiter(_recruiterAddress, _companyId),
            "Company-Recruiter: Recruiter already connected with Company"
        );

        recruitersInCompany[_recruiterAddress][_companyId] = true;
        bool isIn = recruitersInCompany[_recruiterAddress][_companyId];

        emit ConnectCompanyRecruiter(_recruiterAddress, _companyId, isIn);
    }

    // only recruiter -> resumiro
    // param _recruiterAddress must equal msg.sender -> resmiro
    // company must existed
    // recruiter must not in company
    function disconnectCompanyRecruiter(
        address _recruiterAddress,
        uint _companyId
    ) public virtual {
        require(companies[_companyId].exist, "Company-Recruiter: ID not exist");
        require(
            isExistedCompanyRecruiter(_recruiterAddress, _companyId),
            "Company-Recruiter: Recruiter not connect with Company"
        );

        recruitersInCompany[msg.sender][_companyId] = false;
        bool isIn = recruitersInCompany[_recruiterAddress][_companyId];

        emit DisconnectCompanyRecruiter(msg.sender, _companyId, isIn);
    }
}
