// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {Lumberjack} from "../src/Lumberjack.sol";
import {VRFCoordinatorMock} from "./mocks/VRFCoordinatorMock.sol";

contract LumberjackTimerTest is Test {
    Lumberjack public lumberjack;
    VRFCoordinatorMock public vrfCoordinator;

    address public player = address(0x1);
    uint256 public constant INITIAL_TIMER = 5 seconds;
    uint256 public constant TIME_PER_CHOP = 1 seconds;

    event MoveMade(address indexed player, Lumberjack.Move move, uint256 score, uint8 nextBranch, uint256 timerEnd);

    function setUp() public {
        vrfCoordinator = new VRFCoordinatorMock();
        lumberjack = new Lumberjack(address(vrfCoordinator));
        vm.deal(player, 10 ether);
    }

    function testTimerInitialization() public {
        _startGameForPlayer(player, 12345);

        (,,,, uint256 timerEnd,,,,) = lumberjack.games(player);

        // Timer should be initialized to current time + INITIAL_TIMER
        assertEq(timerEnd, block.timestamp + INITIAL_TIMER);
    }

    function testTimerCapMechanism() public {
        _startGameForPlayer(player, 12345);

        // Make moves quickly to test timer cap
        for (uint256 i = 0; i < 5; i++) {
            (,,,,,, uint8 nextBranch,,) = lumberjack.games(player);
            Lumberjack.Move safeMove =
                nextBranch == uint8(Lumberjack.BranchSide.LEFT) ? Lumberjack.Move.RIGHT : Lumberjack.Move.LEFT;

            vm.prank(player);
            lumberjack.makeMove(safeMove);

            // Check timer after each move
            (,,,, uint256 timerEnd,,,,) = lumberjack.games(player);
            uint256 timeRemaining = timerEnd - block.timestamp;

            console2.log("Move", i + 1);
            console2.log("Time remaining:", timeRemaining);

            // Timer should never exceed INITIAL_TIMER
            assertLe(timeRemaining, INITIAL_TIMER, "Timer exceeded cap");
        }
    }

    function testTimerDoesNotIncreaseWhenAtCap() public {
        _startGameForPlayer(player, 12345);

        // Get initial timer
        (,,,, uint256 initialTimerEnd,,,,) = lumberjack.games(player);

        // Make a move immediately (timer should be at cap)
        (,,,,,, uint8 nextBranch,,) = lumberjack.games(player);
        Lumberjack.Move safeMove =
            nextBranch == uint8(Lumberjack.BranchSide.LEFT) ? Lumberjack.Move.RIGHT : Lumberjack.Move.LEFT;

        vm.prank(player);
        lumberjack.makeMove(safeMove);

        (,,,, uint256 newTimerEnd,,,,) = lumberjack.games(player);

        // Timer should not increase beyond initial timer
        uint256 expectedTimer = initialTimerEnd; // No time added since we're at cap
        assertEq(newTimerEnd, expectedTimer, "Timer increased when at cap");
    }

    function testTimerIncreasesWhenBelowCap() public {
        _startGameForPlayer(player, 12345);

        // Wait for timer to decrease below cap
        vm.warp(block.timestamp + 5 seconds);

        // Get timer before move
        (,,,, uint256 timerBeforeMove,,,,) = lumberjack.games(player);
        uint256 timeRemainingBefore = timerBeforeMove - block.timestamp;
        console2.log("Time remaining before move:", timeRemainingBefore);

        // Make a move
        (,,,,,, uint8 nextBranch,,) = lumberjack.games(player);
        Lumberjack.Move safeMove =
            nextBranch == uint8(Lumberjack.BranchSide.LEFT) ? Lumberjack.Move.RIGHT : Lumberjack.Move.LEFT;

        vm.prank(player);
        lumberjack.makeMove(safeMove);

        (,,,, uint256 timerAfterMove,,,,) = lumberjack.games(player);
        uint256 timeRemainingAfter = timerAfterMove - block.timestamp;
        console2.log("Time remaining after move:", timeRemainingAfter);

        // Timer should increase by TIME_PER_CHOP
        assertEq(timerAfterMove, timerBeforeMove + TIME_PER_CHOP, "Timer did not increase correctly");
    }

    function testTimerBehaviorNearCap() public {
        _startGameForPlayer(player, 12345);

        // Wait so timer is just below cap
        vm.warp(block.timestamp + 1 seconds); // 29 seconds remaining

        (,,,, uint256 timerBefore,,,,) = lumberjack.games(player);
        uint256 timeRemainingBefore = timerBefore - block.timestamp;
        console2.log("Time remaining before move:", timeRemainingBefore);

        // Make a move
        (,,,,,, uint8 nextBranch,,) = lumberjack.games(player);
        Lumberjack.Move safeMove =
            nextBranch == uint8(Lumberjack.BranchSide.LEFT) ? Lumberjack.Move.RIGHT : Lumberjack.Move.LEFT;

        vm.prank(player);
        lumberjack.makeMove(safeMove);

        (,,,, uint256 timerAfter,,,,) = lumberjack.games(player);
        uint256 timeRemainingAfter = timerAfter - block.timestamp;
        console2.log("Time remaining after move:", timeRemainingAfter);

        // Timer should be capped at INITIAL_TIMER
        assertEq(timeRemainingAfter, INITIAL_TIMER, "Timer not capped correctly");
    }

    function testRapidMovesWithTimerCap() public {
        _startGameForPlayer(player, 12345);

        // Make many moves rapidly
        uint256 movesToMake = 20;
        uint256[] memory timersAfterMove = new uint256[](movesToMake);

        for (uint256 i = 0; i < movesToMake; i++) {
            (,,,,,, uint8 nextBranch,,) = lumberjack.games(player);
            Lumberjack.Move safeMove =
                nextBranch == uint8(Lumberjack.BranchSide.LEFT) ? Lumberjack.Move.RIGHT : Lumberjack.Move.LEFT;

            vm.prank(player);
            lumberjack.makeMove(safeMove);

            (,,,, uint256 timerEnd,,,,) = lumberjack.games(player);
            timersAfterMove[i] = timerEnd - block.timestamp;
        }

        // All timers should be at or below cap
        for (uint256 i = 0; i < movesToMake; i++) {
            assertLe(timersAfterMove[i], INITIAL_TIMER, "Timer exceeded cap during rapid moves");
        }
    }

    function testTimerAfterLongWait() public {
        _startGameForPlayer(player, 12345);

        // Wait for a long time (timer runs low)
        vm.warp(block.timestamp + 3 seconds); // 2 seconds remaining

        // Make multiple moves
        for (uint256 i = 0; i < 10; i++) {
            (,,,, uint256 timerBefore,,,,) = lumberjack.games(player);
            uint256 timeRemainingBefore = timerBefore > block.timestamp ? timerBefore - block.timestamp : 0;

            (,,,,,, uint8 nextBranch,,) = lumberjack.games(player);
            Lumberjack.Move safeMove =
                nextBranch == uint8(Lumberjack.BranchSide.LEFT) ? Lumberjack.Move.RIGHT : Lumberjack.Move.LEFT;

            vm.prank(player);
            lumberjack.makeMove(safeMove);

            (,,,, uint256 timerAfter,,,,) = lumberjack.games(player);
            uint256 timeRemainingAfter = timerAfter - block.timestamp;

            console2.log("Move", i + 1);
            console2.log("Before:", timeRemainingBefore);
            console2.log("After:", timeRemainingAfter);

            // Timer should increase but stay within cap
            assertLe(timeRemainingAfter, INITIAL_TIMER, "Timer exceeded cap");

            // If we had room to add time, it should have been added
            if (timeRemainingBefore + TIME_PER_CHOP <= INITIAL_TIMER) {
                assertEq(timerAfter, timerBefore + TIME_PER_CHOP, "Timer did not increase when below cap");
            }
        }
    }

    function testTimerEdgeCaseAtExactCap() public {
        _startGameForPlayer(player, 12345);

        // Set timer to exactly (INITIAL_TIMER - TIME_PER_CHOP)
        vm.warp(block.timestamp + TIME_PER_CHOP); // 28 seconds remaining

        (,,,, uint256 timerBefore,,,,) = lumberjack.games(player);
        uint256 timeRemainingBefore = timerBefore - block.timestamp;
        assertEq(timeRemainingBefore, INITIAL_TIMER - TIME_PER_CHOP, "Setup failed");

        // Make a move
        (,,,,,, uint8 nextBranch,,) = lumberjack.games(player);
        Lumberjack.Move safeMove =
            nextBranch == uint8(Lumberjack.BranchSide.LEFT) ? Lumberjack.Move.RIGHT : Lumberjack.Move.LEFT;

        vm.prank(player);
        lumberjack.makeMove(safeMove);

        (,,,, uint256 timerAfter,,,,) = lumberjack.games(player);
        uint256 timeRemainingAfter = timerAfter - block.timestamp;

        // Timer should be exactly at cap
        assertEq(timeRemainingAfter, INITIAL_TIMER, "Timer not at exact cap");
    }

    function testTimerLogicWithDifferentTimestamps() public {
        // Test at different time points
        uint256[] memory waitTimes = new uint256[](5);
        waitTimes[0] = 0; // No wait
        waitTimes[1] = 1; // 1 second
        waitTimes[2] = 2; // 2 seconds
        waitTimes[3] = 3; // 3 seconds
        waitTimes[4] = 4; // 4 seconds

        for (uint256 i = 0; i < waitTimes.length; i++) {
            // Start fresh game for each test
            address testPlayer = address(uint160(0x100 + i));
            vm.deal(testPlayer, 10 ether);
            _startGameForPlayer(testPlayer, 12345 + i);

            // Wait specified time
            if (waitTimes[i] > 0) {
                vm.warp(block.timestamp + waitTimes[i]);
            }

            (,,,, uint256 timerBefore,,,,) = lumberjack.games(testPlayer);
            uint256 timeRemainingBefore = timerBefore - block.timestamp;

            // Make a move
            (,,,,,, uint8 nextBranch,,) = lumberjack.games(testPlayer);
            Lumberjack.Move safeMove =
                nextBranch == uint8(Lumberjack.BranchSide.LEFT) ? Lumberjack.Move.RIGHT : Lumberjack.Move.LEFT;

            vm.prank(testPlayer);
            lumberjack.makeMove(safeMove);

            (,,,, uint256 timerAfter,,,,) = lumberjack.games(testPlayer);
            uint256 timeRemainingAfter = timerAfter - block.timestamp;

            console2.log("Wait time:", waitTimes[i]);
            console2.log("Before:", timeRemainingBefore);
            console2.log("After:", timeRemainingAfter);

            // Verify timer behavior
            if (timeRemainingBefore + TIME_PER_CHOP <= INITIAL_TIMER) {
                // Should add time
                assertEq(timerAfter, timerBefore + TIME_PER_CHOP, "Timer should increase");
            } else {
                // Should not add time (at cap)
                assertEq(timerAfter, timerBefore, "Timer should not increase at cap");
            }

            // Always verify cap
            assertLe(timeRemainingAfter, INITIAL_TIMER, "Timer exceeded cap");
        }
    }

    // Helper function
    uint256 private requestIdCounter = 1;

    function _startGameForPlayer(address _player, uint256 seed) private {
        vm.prank(_player);
        lumberjack.startGame();

        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = seed;
        vrfCoordinator.fulfillRandomNumbers(requestIdCounter++, randomWords);
    }
}
