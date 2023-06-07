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
    bytes32 public constant ADMIN_RECRUITER_ROLE = keccak256("ADMIN_RECRUITER_ROLE");

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
        ExpStatus status,
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
    event ChangeExpStatus (
        uint id,
        ExpStatus status,
        address indexed admin_recruiter
    );
    event DeleteExperience(
        uint id,
        string position,
        string start,
        string finish,
        uint company_id,
        ExpStatus status,
        address indexed user_address
    );

    //=============================ERRORS==========================================
    error User__NoRole(address account);

    error Experience__AlreadyExisted(uint experience_id, address user_address);
    error Experience__NotExisted(uint experience_id, address user_address);
    error Experience__Rejected(uint experience_id);
    error Experience__NotPending(uint experience_id);

    error Company__NotExisted(uint experience_id, uint company_id);
    error User__NotExisted(address user_address);
    error Company__NotCreator(uint company_id, address caller);

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

    modifier onlyCandidateOrRecruiter() {
        if (
            !(  user.hasRole(tx.origin, RECRUITER_ROLE) &&
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
    ) internal onlyCandidateOrRecruiter {
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
            ExpStatus.Pending,
            0, // 0 is not verified yet
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
            exp.status,
            _user
        );
    }

    // only user -> later⏳ -> done✅
    // exp status is not rejected/verified -> done✅
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
    ) internal onlyCandidateOrRecruiter {
        if (tx.origin != _user) {
            revert("param and call not match");
        }
        if (experiences[_id].status != ExpStatus.Pending) {
            revert Experience__NotPending({
                experience_id: _id
            });
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

    // only admin-recruiter -> done✅
    // exp id must existed -> done✅
    // admin-recruiter is creator of company -> done✅
    // cannot change status with rejected -> done✅
    // new ⭐
    function _changeExpStatus(uint _id, uint _status, uint _verifiedAt) internal onlyRole(ADMIN_RECRUITER_ROLE) {
        if (!experienceIds.contains(_id)) {
            revert Experience__NotExisted({experience_id: _id, user_address: address(0)});
        }

        if (!company.isCreator(experiences[_id].companyId, tx.origin)) {
            revert Company__NotCreator({
                company_id: _id,
                caller: tx.origin
            });
        }

        if (experiences[_id].status == ExpStatus.Rejected) {
            revert Experience__Rejected({
                experience_id: _id
            });
        }

        experiences[_id].status = ExpStatus(_status);

        if (experiences[_id].status == ExpStatus.Verified) {
            experiences[_id].verifiedAt = _verifiedAt;
            // new ⭐
            company.connectCompanyRecruiter(experiences[_id].owner, experiences[_id].companyId);
        }
        
        AppExperience memory exp = experiences[_id];

        emit ChangeExpStatus(
            _id,
            exp.status,
            tx.origin
        );
    }

    // only user -> later⏳ -> done✅
    // param _user must equal msg.sender -> later⏳ -> done✅
    // experience id must existed -> done✅
    // just for user -> done✅
    // experience have been connected with user yet -> done✅
    function _deleteExperience(uint _id, address _user) internal onlyCandidateOrRecruiter {
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
            exp.status,
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

    function changeExpStatus(uint _id, uint _status, uint _verifiedAt) external {
        _changeExpStatus(_id, _status, _verifiedAt);
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
