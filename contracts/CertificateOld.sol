// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.18;

// import "./library/EnumrableSet.sol";
// import "../interfaces/IUser.sol";
// import "../interfaces/ICertificate.sol";
// import "./library/UintArray.sol";

// contract Certificate is ICertificate {
//     using EnumerableSet for EnumerableSet.UintSet;

//     //=============================ATTRIBUTES==========================================
//     IUser user;
//     EnumerableSet.UintSet certificateIds; // [cert_id]
//     uint certificateCounter = 1;
//     mapping(uint => AppCertificate) certs; // {cert_id: cert}
//     mapping(address => EnumerableSet.UintSet) candidateOwnCert; // {candidate_address: [certId]}

//     constructor(address _userContract) {
//         user = IUser(_userContract);
//     }

//     //=============================EVENTS==========================================
//     event AddCertificate(
//         uint id,
//         string name,
//         uint verified_at,
//         address indexed owner_address
//     );
//     event UpdateCertificate(
//         uint id,
//         string name,
//         uint verified_at,
//         address indexed owner_address
//     );
//     event DeleteCertificate(
//         uint id,
//         string name,
//         uint verified_at,
//         address indexed owner_address
//     );

//     //=============================ERRORS==========================================
//     error NotExisted(uint id);
//     error AlreadyExisted(uint id);
//     error NotOwned(uint id, address candidate_address);

//     error NotCandidate(address user_address);

//     //=============================METHODs==========================================
//     //==================CERTIFICATES=======================
//     function _isOwnerOfCertificate(
//         address _candidateAddress,
//         uint _id
//     ) internal view returns (bool) {
//         return candidateOwnCert[_candidateAddress].contains(_id);
//     }

//     function _getCertificate(
//         uint _id
//     ) internal view returns (AppCertificate memory) {
//         return certs[_id];
//     }

//     // only candidate -> later⏳
//     // param _candidateAddress must equal msg.sender -> later⏳
//     // id must not existed -> done✅
//     // just add for candidate -> done✅
//     function _addCertificate(
//         string memory _name,
//         uint _verifiedAt,
//         address _candidateAddress
//     ) internal {
//         uint _id = certificateCounter;
//         certificateCounter++;
//         if (certs[_id].exist) {
//             revert AlreadyExisted({id: _id});
//         }
//         if (
//             !(user.isExisted(_candidateAddress) &&
//                 user.hasType(_candidateAddress, 0))
//         ) {
//             revert NotCandidate({user_address: _candidateAddress});
//         }

//         certs[_id] = AppCertificate(
//             _id,
//             certificateIds.length,
//             _name,
//             _verifiedAt,
//             _candidateAddress,
//             true
//         );
//         candidateOwnCert[_id] = _candidateAddress;
//         certificateIds.push(_id);

//         emit AddCertificate(_id, _name, _verifiedAt, _candidateAddress);
//     }

//     // only candidate -> later⏳
//     // candidate must own certificate -> later⏳
//     // id must not existed -> later⏳
//     function _updateCertificate(
//         uint _id,
//         string memory _name,
//         uint _verifiedAt
//     ) internal {
//         if (!certs[_id].exist) {
//             revert NotExisted({id: _id});
//         }

//         // if (isOwnerOfCertificate(msg.sender, _id)) {
//         //     revert NotOwned({id: _id, candidate_address: msg.sender});
//         // }

//         certs[_id].name = _name;
//         certs[_id].verifiedAt = _verifiedAt;
//         AppCertificate memory cert = certs[_id];

//         address candidateAddress = candidateOwnCert[_id];

//         emit UpdateCertificate(
//             _id,
//             cert.name,
//             cert.verifiedAt,
//             candidateAddress
//         );
//     }

//     // only candidate -> later⏳
//     // candidate must own certificate -> later⏳
//     // id must not existed -> done✅
//     function _deleteCertificate(uint _id) internal {
//         if (!certs[_id].exist) {
//             revert NotExisted({id: _id});
//         }

//         if (_isOwnerOfCertificate(msg.sender, _id)) {
//             revert NotOwned({id: _id, candidate_address: msg.sender});
//         }

//         certs[certificateIds[certificateIds.length - 1]].index = certs[_id]
//             .index;
//         UintArray.remove(certificateIds, certs[_id].index);

//         AppCertificate memory certificate = certs[_id];
//         address ownerAddress = candidateOwnCert[_id];
//         delete certs[_id];
//         delete candidateOwnCert[_id];

//         emit DeleteCertificate(
//             _id,
//             certificate.name,
//             certificate.verifiedAt,
//             ownerAddress
//         );
//     }

//     //==================FOR INTERFACE=======================
//     function isOwnerOfCertificate(
//         address _candidateAddress,
//         uint _id
//     ) external view returns (bool) {
//         return _isOwnerOfCertificate(_candidateAddress, _id);
//     }

//     function getCertificate(
//         uint _id
//     ) external view returns (AppCertificate memory) {
//         return _getCertificate(_id);
//     }

//     // only candidate -> later⏳
//     // param _candidateAddress must equal msg.sender -> later⏳
//     // id must not existed -> done✅
//     // just add for candidate -> done✅
//     function addCertificate(
//         string memory _name,
//         uint _verifiedAt,
//         address _candidateAddress
//     ) external {
//         _addCertificate(_name, _verifiedAt, _candidateAddress);
//     }

//     // only candidate -> later⏳
//     // candidate must own certificate -> later⏳
//     // id must not existed -> later⏳
//     function updateCertificate(
//         uint _id,
//         string memory _name,
//         uint _verifiedAt
//     ) external {
//         _updateCertificate(_id, _name, _verifiedAt);
//     }

//     // only candidate -> later⏳
//     // candidate must own certificate -> later⏳
//     // id must not existed -> done✅
//     function deleteCertificate(uint _id) external {
//         _deleteCertificate(_id);
//     }

//     //======================INTERFACE SETTER==========================
//     function setUserInterface(address _contract) public {
//         user = IUser(_contract);
//     }
// }
