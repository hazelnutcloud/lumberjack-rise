// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {Lumberjack} from "../src/Lumberjack.sol";

contract DeployLumberjack is Script {
    // Default values for different networks
    struct NetworkConfig {
        address vrfCoordinator;
        uint256 subscriptionId;
        bytes32 keyHash;
        uint32 callbackGasLimit;
    }

    NetworkConfig public activeNetworkConfig;

    // Network configs
    uint256 constant ETHEREUM_MAINNET_CHAIN_ID = 1;
    uint256 constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant POLYGON_MAINNET_CHAIN_ID = 137;
    uint256 constant POLYGON_MUMBAI_CHAIN_ID = 80001;
    uint256 constant ARBITRUM_MAINNET_CHAIN_ID = 42161;
    uint256 constant ARBITRUM_SEPOLIA_CHAIN_ID = 421614;
    uint256 constant BASE_MAINNET_CHAIN_ID = 8453;
    uint256 constant BASE_SEPOLIA_CHAIN_ID = 84532;

    function run() external returns (Lumberjack) {
        setNetworkConfig();

        vm.startBroadcast();

        Lumberjack lumberjack = new Lumberjack(
            activeNetworkConfig.vrfCoordinator,
            activeNetworkConfig.subscriptionId,
            activeNetworkConfig.keyHash,
            activeNetworkConfig.callbackGasLimit
        );

        console2.log("Lumberjack deployed at:", address(lumberjack));
        console2.log("VRF Coordinator:", activeNetworkConfig.vrfCoordinator);
        console2.log("Subscription ID:", activeNetworkConfig.subscriptionId);

        vm.stopBroadcast();

        return lumberjack;
    }

    function setNetworkConfig() private {
        uint256 chainId = block.chainid;

        if (chainId == SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getSepoliaConfig();
        } else if (chainId == POLYGON_MUMBAI_CHAIN_ID) {
            activeNetworkConfig = getMumbaiConfig();
        } else if (chainId == ARBITRUM_SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getArbitrumSepoliaConfig();
        } else if (chainId == BASE_SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getBaseSepoliaConfig();
        } else if (chainId == ETHEREUM_MAINNET_CHAIN_ID) {
            activeNetworkConfig = getMainnetConfig();
        } else if (chainId == POLYGON_MAINNET_CHAIN_ID) {
            activeNetworkConfig = getPolygonMainnetConfig();
        } else if (chainId == ARBITRUM_MAINNET_CHAIN_ID) {
            activeNetworkConfig = getArbitrumMainnetConfig();
        } else if (chainId == BASE_MAINNET_CHAIN_ID) {
            activeNetworkConfig = getBaseMainnetConfig();
        } else {
            // Local network
            activeNetworkConfig = getAnvilConfig();
        }
    }

    function getSepoliaConfig() private pure returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            subscriptionId: 0, // Must be set via environment variable
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 100000
        });
    }

    function getMumbaiConfig() private pure returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinator: 0x343300b5d84D444B2ADc9116FEF1bED02BE49Cf2,
            subscriptionId: 0, // Must be set via environment variable
            keyHash: 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f,
            callbackGasLimit: 100000
        });
    }

    function getArbitrumSepoliaConfig() private pure returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinator: 0x5CE8D5A2BC84beb22a398CCA51996F7930313D61,
            subscriptionId: 0, // Must be set via environment variable
            keyHash: 0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be,
            callbackGasLimit: 100000
        });
    }

    function getBaseSepoliaConfig() private pure returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinator: 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634,
            subscriptionId: 0, // Must be set via environment variable
            keyHash: 0x06eb0e2ea7cca202fc7c8258397a36f33d88568d2522b37aaa3b14ff6ee1b696,
            callbackGasLimit: 100000
        });
    }

    function getMainnetConfig() private pure returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinator: 0xD7f86b4b8Cae7D942340FF628F82735b7a20893a,
            subscriptionId: 0, // Must be set via environment variable
            keyHash: 0x8077df514608a09f83e4e8d300645594e5d7234665448ba83f51a50f842bd3d9,
            callbackGasLimit: 100000
        });
    }

    function getPolygonMainnetConfig() private pure returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinator: 0xec0Ed46f36576541C75739E915ADbCb3DE24bD77,
            subscriptionId: 0, // Must be set via environment variable
            keyHash: 0x719ed7d7664815b4a9b0c8f4d6e7c0e2e3234462617e99c2d52334b716243a34,
            callbackGasLimit: 100000
        });
    }

    function getArbitrumMainnetConfig() private pure returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinator: 0x3C0Ca683b403E37668AE3DC4FB62F4B29B6f7a3e,
            subscriptionId: 0, // Must be set via environment variable
            keyHash: 0x9e9e46732b32662b9adc6f3abcb5a9f61aab3e31f97b2ee3a5d77e6f0a06fcf8,
            callbackGasLimit: 100000
        });
    }

    function getBaseMainnetConfig() private pure returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinator: 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634,
            subscriptionId: 0, // Must be set via environment variable
            keyHash: 0x06eb0e2ea7cca202fc7c8258397a36f33d88568d2522b37aaa3b14ff6ee1b696,
            callbackGasLimit: 100000
        });
    }

    function getAnvilConfig() private pure returns (NetworkConfig memory) {
        // For local testing, we'll deploy a mock
        return NetworkConfig({
            vrfCoordinator: address(0), // Will be deployed in test
            subscriptionId: 1,
            keyHash: 0x0000000000000000000000000000000000000000000000000000000000000000,
            callbackGasLimit: 100000
        });
    }
}
