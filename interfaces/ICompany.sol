// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IUser.sol";

interface ICompany {
    struct AppCompany {
        uint256 index;
        uint id;
        string name;
        string website;
        string location;
        string addr;
        bool exist;
    }

    function isExistedCompanyRecruiter(
        address _recruiterAddress,
        uint _companyId
    ) external view returns (bool);

    function isExistedCompany(uint _id) external view returns (bool);

    function getCompany(uint _id) external view returns (AppCompany memory);

    function getAllCompanies() external view returns (AppCompany[] memory);

    function addCompany(
        uint _id,
        string memory _name,
        string memory _website,
        string memory _location,
        string memory _addr
    ) external;

    function updateCompany(
        uint _id,
        string memory _name,
        string memory _website,
        string memory _location,
        string memory _addr
    ) external;

    function deleteCompany(uint _id) external;

    function connectCompanyRecruiter(
        address _recruiterAddress,
        uint _companyId
    ) external;

    function disconnectCompanyRecruiter(
        address _recruiterAddress,
        uint _companyId
    ) external;

    function getAllCompaniesConnectedRecruiter(
        address _recruiterAddress
    ) external view returns (AppCompany[] memory);

    function getAllRecruitersConnectedCompany(
        uint _companyId
    ) external view returns (IUser.AppUser[] memory);
}
