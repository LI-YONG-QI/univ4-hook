// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";

contract MultiHooks is BaseHook {
    struct Call {
        bytes4 selector;
        bytes data;
    }

    mapping(bytes4 selector => address target) public subHooks;

    constructor(IPoolManager _manager) BaseHook(_manager) {}

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: true,
            afterInitialize: true,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function addSubHook(bytes4 selector, address target) external {
        subHooks[selector] = target;
    }

    function afterSwap(address, PoolKey calldata, uint160, bytes calldata hookData) external virtual returns (bytes4) {
        Call[] memory calls = abi.decode(hookData, (Call[]));

        for (uint256 i = 0; i < calls.length; i++) {
            Call memory call = calls[i];
            require(subHooks[call.selector] != address(0), "MultiHooks: subHook not set");
            (bool success,) = subHooks[call.selector].call(call.data);
            require(success, "MultiHooks: subHook failed");
        }
        return this.beforeInitialize.selector;
    }

    function getTarget(bytes4 selector) external view returns (address) {
        require(subHooks[selector] != address(0), "Not active");

        return subHooks[selector];
    }
}
