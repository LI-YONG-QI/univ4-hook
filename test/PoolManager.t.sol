// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {PoolManager} from "v4-core/PoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId} from "v4-core/types/PoolId.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {LPFeeLibrary} from "v4-core/libraries/LPFeeLibrary.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract PoolManagerTest is Test {
    using LPFeeLibrary for uint24;
    using StateLibrary for IPoolManager;

    /// sqrtPriceX96 = floor(sqrt(A / B) * 2 ** 96) where A and B are the currency reserves
    uint160 public constant SQRT_PRICE_1_1 = 79228162514264337593543950336; // A : B = 1 : 1;
    bytes constant ZERO_BYTES = new bytes(0);

    IPoolManager manager;
    IHooks hooks = IHooks(address(0));
    Currency c0;
    Currency c1;

    uint24 fee = 3000;
    int24 tickSpacing = 60;

    function _initTokens() internal returns (Currency, Currency) {
        MockERC20 token0 = new MockERC20("TEST", "TEST", 18);
        MockERC20 token1 = new MockERC20("TEST", "TEST", 18);

        c0 = Currency.wrap(address(token0));
        c1 = Currency.wrap(address(token1));

        return (c0, c1);
    }

    function _getPoolKey() internal view returns (PoolKey memory key) {
        key = PoolKey(c0, c1, fee, tickSpacing, hooks);
    }

    function setUp() public {
        manager = new PoolManager();
        _initTokens();
    }

    function test_poolIdNotEq() public view {
        PoolKey memory key = _getPoolKey();
        bytes32 id = PoolId.unwrap(key.toId());

        PoolKey memory key2 = PoolKey(c0, c1, fee, tickSpacing, IHooks(address(1)));
        bytes32 id2 = PoolId.unwrap(key2.toId());
        assertNotEq(id, id2);
    }

    function test_initializePool() public {
        PoolKey memory key = _getPoolKey();

        vm.expectEmit(true, true, true, true);
        emit IPoolManager.Initialize(
            key.toId(), c0, c1, fee, 60, hooks, SQRT_PRICE_1_1, TickMath.getTickAtSqrtPrice(SQRT_PRICE_1_1)
        );
        manager.initialize(key, SQRT_PRICE_1_1, ZERO_BYTES);

        (uint160 sqrtPriceX96, int24 tick, uint24 protocolFee, uint24 lpFee) = manager.getSlot0(key.toId());
        assertEq(sqrtPriceX96, SQRT_PRICE_1_1);
        assertEq(tick, TickMath.getTickAtSqrtPrice(SQRT_PRICE_1_1));
        assertEq(lpFee, fee);
        assertEq(protocolFee, 0); //? How to determine the protocolFee
    }

    // function test_addLiquidity() public {
    //     PoolKey memory key = _getPoolKey();
    //     manager.initialize(key, SQRT_PRICE_1_1, ZERO_BYTES);

    //     IPoolManager.ModifyLiquidityParams memory params = IPoolManager.ModifyLiquidityParams(0, 1, 1, bytes32(0));
    //     manager.modifyLiquidity(key, params, ZERO_BYTES);
    // }
}
