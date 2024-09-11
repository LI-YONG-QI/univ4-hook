// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {PoolManager} from "v4-core/PoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId} from "v4-core/types/PoolId.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {LPFeeLibrary} from "v4-core/libraries/LPFeeLibrary.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract PoolManagerTest is Test {
    using LPFeeLibrary for uint24;

    uint160 public constant SQRT_PRICE_1_1 = 79228162514264337593543950336;
    bytes constant ZERO_BYTES = new bytes(0);
    IPoolManager manager;

    function _initTokens() internal returns (Currency, Currency) {
        MockERC20 token0 = new MockERC20("TEST", "TEST", 18);
        MockERC20 token1 = new MockERC20("TEST", "TEST", 18);

        Currency currency0 = Currency.wrap(address(token0));
        Currency currency1 = Currency.wrap(address(token1));

        return (currency0, currency1);
    }

    function setUp() public {
        manager = new PoolManager();
    }

    function test_initializePool() public {
        (Currency currency0, Currency currency1) = _initTokens();
        uint24 fee = 3000;
        IHooks hooks = IHooks(address(0));
        int24 tickSpacing = fee.isDynamicFee() ? int24(60) : int24(fee / 100 * 2);
        PoolKey memory key = PoolKey(currency0, currency1, fee, tickSpacing, hooks);
        manager.initialize(key, SQRT_PRICE_1_1, ZERO_BYTES);
        bytes32 id = PoolId.unwrap(key.toId());

        PoolKey memory key2 = PoolKey(currency0, currency1, fee, tickSpacing, IHooks(address(1)));
        bytes32 id2 = PoolId.unwrap(key2.toId());
        assertNotEq(id, id2);
    }
}
