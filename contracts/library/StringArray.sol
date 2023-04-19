// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StringArray {
    function remove(string[] storage _arr, uint _i) internal {
        string memory temp = _arr[_arr.length - 1];
        _arr[_arr.length - 1] = _arr[_i];
        _arr[_i] = temp;
        _arr.pop();
    }

    function removeElement(string[] storage _arr, string memory _e) internal {
        for (uint i = 0; i < _arr.length; i++) {
            if (keccak256(bytes(_arr[i])) == keccak256(bytes(_e))) {
                remove(_arr, i);
                break;
            }
        }
    }

    function isElementExisted(string[] storage _arr, string memory _e) internal view returns (bool) {
        for (uint i = 0; i < _arr.length; i++) {
            if (keccak256(bytes(_arr[i])) == keccak256(bytes(_e))) {
                return true;
            }
            return false;
        }
    }

    function isElementExistedMemory(string[] memory _arr, string memory _e) internal pure returns (bool) {
        for (uint i = 0; i < _arr.length; i++) {
            if (keccak256(bytes(_arr[i])) == keccak256(bytes(_e))) {
                return true;
            }
            return false;
        }
    }
}
