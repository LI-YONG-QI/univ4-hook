// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {MultiHooks} from "../MultiHooks.sol";
import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

contract MultiHooksStub is MultiHooks {
    constructor(IPoolManager manager) MultiHooks(manager) {}

    // make this a no-op in testing
    function validateHookAddress(BaseHook _this) internal pure override {}
}
