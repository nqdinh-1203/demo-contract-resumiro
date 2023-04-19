// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICompany {
    function isExistedCompanyRecruiter(
        address _recruiterAddress,
        uint _companyId
    ) external view returns (bool);

    function isExistedCompany(uint _id) external view returns (bool);
}
