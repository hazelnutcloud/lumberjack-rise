// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {Lumberjack} from "../src/Lumberjack.sol";

contract DeployLumberjack is Script {
    // Fast VRF Coordinator address on RISE Chain
    address constant VRF_COORDINATOR_RISE = 0x9d57aB4517ba97349551C876a01a7580B1338909;

    function run() external returns (Lumberjack) {
        vm.startBroadcast();

        Lumberjack lumberjack = new Lumberjack(VRF_COORDINATOR_RISE);

        console2.log("Lumberjack deployed at:", address(lumberjack));
        console2.log("Fast VRF Coordinator:", VRF_COORDINATOR_RISE);
        console2.log("Network: RISE Chain");

        vm.stopBroadcast();

        return lumberjack;
    }
}
