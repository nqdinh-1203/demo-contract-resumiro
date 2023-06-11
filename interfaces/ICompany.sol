// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IUser.sol";

interface ICompany {
    struct AppCompany {
        uint id;
        string name;
        string website;
        string location;
        string addr;
        address creator;
    }

    function isCreator(uint _id, address caller) external view returns (bool);

    function isExistedCompanyUser(
        address _userAddress,
        uint _companyId
    ) external view returns (bool);

    function isExistedCompany(uint _id) external view returns (bool);

    function getCompany(uint _id) external view returns (AppCompany memory);

    function getAllCompanies() external view returns (AppCompany[] memory);

    function getLatestCompanyId() external view returns (uint);

    function addCompany(
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

    function connectCompanyUser(address _userAddress, uint _companyId) external;

    function disconnectCompanyUser(
        address _userAddress,
        uint _companyId
    ) external;

    function getAllCompaniesConnectedUser(
        address _userAddress
    ) external view returns (AppCompany[] memory);

    function getAllUsersConnectedCompany(
        uint _companyId
    ) external view returns (IUser.AppUser[] memory);
}
