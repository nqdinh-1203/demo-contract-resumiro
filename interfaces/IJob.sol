// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJob {
    function isExistedJob(uint _jobId) external view returns (bool);
}
