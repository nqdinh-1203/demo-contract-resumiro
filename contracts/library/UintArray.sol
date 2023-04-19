// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library UintArray {
    function remove(uint[] storage _arr, uint _i) internal {
        uint temp = _arr[_arr.length - 1];
        _arr[_arr.length - 1] = _arr[_i];
        _arr[_i] = temp;
        _arr.pop();
    }

    function removeElement(uint[] storage _arr, uint _e) internal {
        for (uint i = 0; i < _arr.length; i++) {
            if (_arr[i] == _e) {
                remove(_arr, i);
                break;
            }
        }
    }

    function isElementExisted(
        uint[] storage _arr,
        uint _e
    ) internal view returns (bool) {
        for (uint i = 0; i < _arr.length; i++) {
            if (_arr[i] == _e) {
                return true;
            }
            return false;
        }
    }

    function isElementExistedMemory(
        uint[] memory _arr,
        uint _e
    ) internal pure returns (bool) {
        for (uint i = 0; i < _arr.length; i++) {
            if (_arr[i] == _e) {
                return true;
            }
            return false;
        }
    }
}
