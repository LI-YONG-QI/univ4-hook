// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {MultiHooksStub} from "../src/test/MultiHooksStub.sol";
import {MultiHooks} from "../src/MultiHooks.sol";
import {Counter} from "../src/test/Counter.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {PoolManager} from "v4-core/PoolManager.sol";

contract MultiHooksTest is Test {
    MultiHooksStub multiHooks;
    IPoolManager manager;

    bytes constant ZERO_BYTES = new bytes(0);

    function setUp() public {
        manager = new PoolManager();
        multiHooks = new MultiHooksStub(manager);
    }

    function test_addSubHooks() public {
        Counter counter = new Counter(10);
        bytes4 counterSelector = counter.increment.selector;
        multiHooks.addSubHook(counterSelector, address(counter));

        address target = multiHooks.getTarget(counterSelector);
        assertEq(target, address(counter), "target should be counter");
    }

    function test_multicallAfterSwap() public {
        Counter counter = new Counter(10);
        Counter counter2 = new Counter(10);
        bytes4 incrementSelector = counter.increment.selector;
        bytes4 decrementSelector = counter.decrement.selector;
        multiHooks.addSubHook(incrementSelector, address(counter));
        multiHooks.addSubHook(decrementSelector, address(counter2));

        bytes memory incrementCalldata = abi.encodeWithSelector(counter.increment.selector, uint256(3));
        bytes memory decrementCalldata = abi.encodeWithSelector(counter2.decrement.selector);
        MultiHooks.Call memory call1 = MultiHooks.Call(incrementSelector, incrementCalldata);
        MultiHooks.Call memory call2 = MultiHooks.Call(decrementSelector, decrementCalldata);

        MultiHooks.Call[] memory calls = new MultiHooks.Call[](2);
        calls[0] = call1;
        calls[1] = call2;

        bytes memory hookData = abi.encode(calls);

        multiHooks.afterSwap(
            address(0),
            PoolKey(Currency.wrap(address(0)), Currency.wrap(address(0)), 0, 0, IHooks(address(0))),
            0,
            hookData
        );

        assertEq(counter.getCount(), 13);
        assertEq(counter2.getCount(), 9);
    }
}
