// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IExperience.sol";
import "../interfaces/ICompany.sol";
import "../interfaces/IUser.sol";
import "./library/UintArray.sol";
import "./library/EnumrableSet.sol";

contract Experience is IExperience {
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant ADMIN_ROLE = 0x00;
    bytes32 public constant CANDIDATE_ROLE = keccak256("CANDIDATE_ROLE");
    bytes32 public constant RECRUITER_ROLE = keccak256("RECRUITER_ROLE");

    //=============================ATTRIBUTES==========================================
    EnumerableSet.UintSet experienceIds;
    uint experienceCounter = 1;
    mapping(uint => AppExperience) experiences;
    mapping(address => EnumerableSet.UintSet) experienceOfUser;

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
        string start,
        string finish,
        uint company_id,
        address indexed user_address
    );
    event UpdateExperience(
        uint id,
        string position,
        string start,
        string finish,
        uint company_id,
        address indexed user_address
    );
    event DeleteExperience(
        uint id,
        string position,
        string start,
        string finish,
        uint company_id,
        address indexed user_address
    );

    //=============================ERRORS==========================================
    error User__NoRole(address account);

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
    modifier onlyRole(bytes32 _role) {
        if (!user.hasRole(tx.origin, _role)) {
            revert User__NoRole({account: tx.origin});
        }
        _;
    }
    //=================EXPERIENCES========================

    modifier onlyUser() {
        if (
            !(user.hasRole(tx.origin, ADMIN_ROLE) &&
                user.hasRole(tx.origin, RECRUITER_ROLE) &&
                user.hasRole(tx.origin, CANDIDATE_ROLE))
        ) {
            revert User__NoRole({account: tx.origin});
        }
        _;
    }

    // only user -> later⏳ -> done✅
    // param _user must equal msg.sender -> later⏳ -> done✅
    // experience id must not existed -> done✅
    // company must existed -> done✅
    // just for user -> done✅
    // experience have not been connected with user yet -> done✅
    function _addExperience(
        string memory _position,
        string memory _start,
        string memory _finish,
        uint _companyId,
        address _user
    ) internal onlyUser {
        if (tx.origin != _user) {
            revert("param and call not match");
        }

        uint _id = experienceCounter;
        experienceCounter++;

        if (experienceIds.contains(_id)) {
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
        if (experienceOfUser[_user].contains(_id)) {
            revert Experience_User__AlreadyConnected({
                experience_id: _id,
                user_address: _user
            });
        }

        experiences[_id] = AppExperience(
            _id,
            _position,
            _start,
            _finish,
            _companyId,
            _user
        );
        experienceOfUser[_user].add(_id);
        experienceIds.add(_id);

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

    // only user -> later⏳ -> done✅
    // experience id must existed -> done✅
    // company must existed -> done✅
    // just for user -> done✅
    function _updateExperience(
        uint _id,
        string memory _position,
        string memory _start,
        string memory _finish,
        uint _companyId,
        address _user
    ) internal onlyUser {
        if (tx.origin != _user) {
            revert("param and call not match");
        }
        if (!experienceIds.contains(_id)) {
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

    // only user -> later⏳ -> done✅
    // param _user must equal msg.sender -> later⏳ -> done✅
    // experience id must existed -> done✅
    // just for user -> done✅
    // experience have been connected with user yet -> done✅
    function _deleteExperience(uint _id, address _user) internal onlyUser {
        if (tx.origin != _user) {
            revert("param and call not match");
        }

        if (!experienceIds.contains(_id)) {
            revert Experience__NotExisted({
                experience_id: _id,
                user_address: _user
            });
        }
        if (!user.isExisted(_user)) {
            revert User__NotExisted({user_address: _user});
        }
        if (!experienceOfUser[_user].contains(_id)) {
            revert Experience_User__NotConnected({
                experience_id: _id,
                user_address: _user
            });
        }

        AppExperience memory exp = experiences[_id];

        experienceIds.remove(_id);
        delete experiences[_id];
        experienceOfUser[_user].remove(_id);

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
        AppExperience[] memory expArr = new AppExperience[](
            experienceIds.length()
        );

        for (uint i = 0; i < expArr.length; i++) {
            expArr[i] = experiences[experienceIds.at(i)];
        }

        return expArr;
    }

    function _getAllExperiencesOf(
        address _userAddress
    ) internal view returns (AppExperience[] memory) {
        AppExperience[] memory expArr = new AppExperience[](
            experienceOfUser[_userAddress].length()
        );

        for (uint i = 0; i < expArr.length; i++) {
            expArr[i] = experiences[experienceOfUser[_userAddress].at(i)];
        }

        return expArr;
    }

    //======================FOR INTERFACE==========================
    function addExperience(
        string memory _position,
        string memory _start,
        string memory _finish,
        uint _companyId,
        address _user
    ) external {
        _addExperience(_position, _start, _finish, _companyId, _user);
    }

    function updateExperience(
        uint _id,
        string memory _position,
        string memory _start,
        string memory _finish,
        uint _companyId,
        address _user
    ) external {
        _updateExperience(_id, _position, _start, _finish, _companyId, _user);
    }

    function deleteExperience(uint _id, address _user) external {
        _deleteExperience(_id, _user);
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
