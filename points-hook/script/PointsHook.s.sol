// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";
import {PointsHook} from "../src/PointsHook.sol";

contract DeployHook is Script {
    /// @dev Deterministic CREATE2 deployer (same address on all EVM chains)
    address constant CREATE2_DEPLOYER =
        address(0x4e59b44847b379578588920cA78FbF26c0B4956C);

    function run() external {
        // ── Configuration ──────────────────────────────────────────────
        // Replace with the PoolManager address for your target chain.
        // Sepolia (Uniswap v4): 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543
        IPoolManager poolManager = IPoolManager(
            vm.envOr(
                "POOL_MANAGER",
                address(0xE03A1074c86CFeDd5C142C4F04F1a1536e203543)
            )
        );

        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        // ── Flag mining ────────────────────────────────────────────────
        // PointsHook only uses the afterSwap hook
        uint160 flags = uint160(Hooks.AFTER_SWAP_FLAG);

        bytes memory constructorArgs = abi.encode(poolManager);

        // Mine a salt that produces a hook address whose bottom 14 bits
        // match the required flags
        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_DEPLOYER,
            flags,
            type(PointsHook).creationCode,
            constructorArgs
        );

        // ── Deployment ─────────────────────────────────────────────────
        vm.startBroadcast(privateKey);

        PointsHook hook = new PointsHook{salt: salt}(poolManager);
        require(address(hook) == hookAddress, "DeployHook: address mismatch");

        vm.stopBroadcast();

        // ── Logging ────────────────────────────────────────────────────
        console.log("PointsHook deployed to:", address(hook));
        console.log("Salt used:", vm.toString(salt));
    }
}
