// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IExperience.sol";
import "../interfaces/ICompany.sol";
import "../interfaces/IUser.sol";
import "./library/UintArray.sol";

contract Experience is IExperience {
    
    //=============================ATTRIBUTES==========================================
    uint[] allExperiences;
    mapping(uint => AppExperience) experiences;
    mapping(address => mapping(uint => bool)) experienceOfUser;
    ICompany company;
    IUser user;

    constructor(address _userContract, address _companyContract) {
        user = IUser(_userContract);
        company = ICompany(_companyContract);
    }

    //=============================EVENTS=====================================
    event AddExperience(
        uint id,
        string position,
        uint start,
        uint finish,
        uint company_id,
        address indexed user_address
    );
    event UpdateExperience(
        uint id,
        string position,
        uint start,
        uint finish,
        uint company_id,
        address indexed user_address
    );
    event DeleteExperience(
        uint id,
        string position,
        uint start,
        uint finish,
        uint company_id,
        address indexed user_address
    );

    //=============================ERRORS==========================================
    error Experience__AlreadyExisted(uint experience_id, address user_address);
    error Experience__NotExisted(uint experience_id, address user_address);

    error Company__NotExisted(uint experience_id, uint company_id);
    error User__NotExisted(address user_address);

    error Experience_User__AlreadyConnected(
        uint experience_id,
        address user_address
    );
    error Experience_User__NotConnected(
        uint experience_id,
        address user_address
    );

    //=============================METHODS==========================================
    //=================EXPERIENCES========================
    // only user -> later⏳
    // param _user must equal msg.sender -> later⏳
    // experience id must not existed -> done✅
    // company must existed -> done✅
    // just for user -> done✅
    // experience have not been connected with user yet -> done✅
    function _addExperience(
        address _user,
        uint _id,
        string memory _position,
        uint _start,
        uint _finish,
        uint _companyId
    ) internal {
        if (experiences[_id].exist) {
            revert Experience__AlreadyExisted({
                experience_id: _id,
                user_address: _user
            });
        }
        if (!company.isExistedCompany(_companyId)) {
            revert Company__NotExisted({
                experience_id: _id,
                company_id: _companyId
            });
        }
        if (!user.isExisted(_user)) {
            revert User__NotExisted({user_address: _user});
        }
        if (experienceOfUser[_user][_id]) {
            revert Experience_User__AlreadyConnected({
                experience_id: _id,
                user_address: _user
            });
        }

        experiences[_id] = AppExperience(
            allExperiences.length,
            _id,
            _position,
            _start,
            _finish,
            _companyId,
            true,
            _user
        );
        experienceOfUser[_user][_id] = true;
        allExperiences.push(_id);

        AppExperience memory exp = experiences[_id];

        emit AddExperience(
            _id,
            exp.position,
            exp.start,
            exp.finish,
            exp.companyId,
            _user
        );
    }

    // only user -> later⏳
    // experience id must existed -> done✅
    // company must existed -> done✅
    // just for user -> done✅
    function _updateExperience(
        address _user,
        uint _id,
        string memory _position,
        uint _start,
        uint _finish,
        uint _companyId
    ) internal {
        if (!experiences[_id].exist) {
            revert Experience__NotExisted({
                experience_id: _id,
                user_address: _user
            });
        }
        if (!company.isExistedCompany(_companyId)) {
            revert Company__NotExisted({
                experience_id: _id,
                company_id: _companyId
            });
        }
        if (!user.isExisted(_user)) {
            revert User__NotExisted({user_address: _user});
        }

        experiences[_id].position = _position;
        experiences[_id].start = _start;
        experiences[_id].finish = _finish;
        experiences[_id].companyId = _companyId;

        AppExperience memory exp = experiences[_id];

        emit UpdateExperience(
            _id,
            exp.position,
            exp.start,
            exp.finish,
            exp.companyId,
            _user
        );
    }

    // only user -> later⏳
    // param _user must equal msg.sender -> later⏳
    // experience id must existed -> done✅
    // just for user -> done✅
    // experience have been connected with user yet -> done✅
    function _deleteExperience(address _user, uint _id) internal {
        if (!experiences[_id].exist) {
            revert Experience__NotExisted({
                experience_id: _id,
                user_address: _user
            });
        }
        if (!user.isExisted(_user)) {
            revert User__NotExisted({user_address: _user});
        }
        if (!experienceOfUser[_user][_id]) {
            revert Experience_User__NotConnected({
                experience_id: _id,
                user_address: _user
            });
        }

        AppExperience memory exp = experiences[_id];

        uint lastIndex = allExperiences.length - 1;
        experiences[allExperiences[lastIndex]].index = experiences[_id].index;
        UintArray.remove(allExperiences, experiences[_id].index);

        delete experiences[_id];
        delete experienceOfUser[_user][_id];

        emit AddExperience(
            _id,
            exp.position,
            exp.start,
            exp.finish,
            exp.companyId,
            _user
        );
    }

    function _getExperience(
        uint _id
    ) internal view returns (AppExperience memory) {
        return experiences[_id];
    }

    function _getAllExperiences()
        internal
        view
        returns (AppExperience[] memory)
    {
        AppExperience[] memory arrExp = new AppExperience[](
            allExperiences.length
        );

        for (uint i = 0; i < arrExp.length; i++) {
            arrExp[i] = experiences[allExperiences[i]];
        }

        return arrExp;
    }

    function _getAllExperiencesOf(
        address _userAddress
    ) internal view returns (AppExperience[] memory) {
        AppExperience[] memory arrExp = new AppExperience[](
            allExperiences.length
        );

        for (uint i = 0; i < arrExp.length; i++) {
            if (experienceOfUser[_userAddress][allExperiences[i]]) {
                arrExp[i] = experiences[allExperiences[i]];
            }
        }

        return arrExp;
    }

    //======================FOR INTERFACE==========================
    function addExperience(
        address _user,
        uint _id,
        string memory _position,
        uint _start,
        uint _finish,
        uint _companyId
    ) external {
        _addExperience(_user, _id, _position, _start, _finish, _companyId);
    }

    function updateExperience(
        address _user,
        uint _id,
        string memory _position,
        uint _start,
        uint _finish,
        uint _companyId
    ) external {
        _updateExperience(_user, _id, _position, _start, _finish, _companyId);
    }

    function deleteExperience(address _user, uint _id) external {
        _deleteExperience(_user, _id);
    }

    function getExperience(
        uint _id
    ) external view returns (AppExperience memory) {
        return _getExperience(_id);
    }

    function getAllExperiences()
        external
        view
        returns (AppExperience[] memory)
    {
        return _getAllExperiences();
    }

    function getAllExperiencesOf(
        address _userAddress
    ) external view returns (AppExperience[] memory) {
        return _getAllExperiencesOf(_userAddress);
    }

    //======================INTERFACES==========================
    function setUserInterface(address _contract) public {
        user = IUser(_contract);
    }

    function setCompanyInterface(address _contract) public {
        company = ICompany(_contract);
    }
}
