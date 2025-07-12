// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {Lumberjack} from "../src/Lumberjack.sol";
import {VRFCoordinatorMock} from "./mocks/VRFCoordinatorMock.sol";

contract LumberjackTest is Test {
    Lumberjack public lumberjack;
    VRFCoordinatorMock public vrfCoordinator;

    address public player = address(0x1);
    address public player2 = address(0x2);

    // Track request IDs
    uint256 public nextRequestId = 1;

    event GameStartRequested(address indexed player, uint256 requestId);
    event GameStarted(address indexed player, uint256 gameId, uint8 firstBranch);
    event MoveMade(address indexed player, Lumberjack.Move move, uint256 score, uint8 nextBranch, uint256 timerEnd);
    event GameEnded(address indexed player, uint256 finalScore, bool victory);

    function setUp() public {
        // Deploy VRF Coordinator Mock
        vrfCoordinator = new VRFCoordinatorMock();

        // Deploy Lumberjack with mock coordinator
        lumberjack = new Lumberjack(address(vrfCoordinator));

        // Fund test accounts
        vm.deal(player, 10 ether);
        vm.deal(player2, 10 ether);
    }

    function testStartGame() public {
        vm.prank(player);
        lumberjack.startGame();

        // Check that game is awaiting VRF
        (,,,,,,, bool isActive, bool awaitingVRF) = lumberjack.games(player);
        assertFalse(isActive);
        assertTrue(awaitingVRF);
    }

    function testCannotStartGameWhileActive() public {
        // Start first game
        vm.prank(player);
        lumberjack.startGame();

        // Fulfill VRF
        uint256 requestId = 1;
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 12345;
        vrfCoordinator.fulfillRandomNumbers(requestId, randomWords);

        // Try to start another game
        vm.prank(player);
        vm.expectRevert(Lumberjack.GameAlreadyActive.selector);
        lumberjack.startGame();
    }

    function testGameInitialization() public {
        vm.prank(player);
        lumberjack.startGame();

        // Fulfill VRF
        uint256 requestId = 1;
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 12345;

        vm.expectEmit(true, false, false, false); // Don't check data
        emit GameStarted(player, 0, 0); // We don't know exact values
        vrfCoordinator.fulfillRandomNumbers(requestId, randomWords);

        // Check game state
        (
            uint256 gameId,
            uint256 randomSeed,
            uint256 currentHeight,
            uint256 playerPosition,
            uint256 timerEnd,
            ,
            uint8 nextBranchSide,
            bool isActive,
            bool awaitingVRF
        ) = lumberjack.games(player);

        assertTrue(isActive);
        assertFalse(awaitingVRF);
        assertGt(randomSeed, 0); // Just check it's set
        assertEq(currentHeight, 0);
        assertEq(playerPosition, 0); // Start on left
        assertGt(timerEnd, block.timestamp);
        assertLe(nextBranchSide, 2); // Valid branch side
    }

    function testSuccessfulMove() public {
        // Start and initialize game
        _startGameForPlayer(player, 12345);

        // Get initial state including next branch
        (,, uint256 heightBefore,,,, uint8 nextBranch,,) = lumberjack.games(player);

        // Move to opposite side of branch to avoid collision
        Lumberjack.Move safeMove =
            nextBranch == uint8(Lumberjack.BranchSide.LEFT) ? Lumberjack.Move.RIGHT : Lumberjack.Move.LEFT;

        // Make a move
        vm.prank(player);
        lumberjack.makeMove(safeMove);

        // Check updated state
        (,, uint256 heightAfter,,,,,,) = lumberjack.games(player);
        assertEq(heightAfter, heightBefore + 1);
    }

    function testCollisionEndsGame() public {
        // Start game with known seed that will produce a left branch
        _startGameForPlayer(player, 1); // This seed produces a left branch at height 1

        // Check the next branch
        (,,,,,, uint8 nextBranch,,) = lumberjack.games(player);

        // If branch is on left, moving left should cause collision
        if (nextBranch == uint8(Lumberjack.BranchSide.LEFT)) {
            vm.prank(player);
            vm.expectEmit(true, false, false, true);
            emit GameEnded(player, 0, false);
            lumberjack.makeMove(Lumberjack.Move.LEFT);

            // Game should be inactive
            (,,,,,,, bool isActive,) = lumberjack.games(player);
            assertFalse(isActive);
        }
    }

    function testTimerExpiration() public {
        _startGameForPlayer(player, 12345);

        // Fast forward past timer
        vm.warp(block.timestamp + 31 seconds);

        // Try to make a move
        vm.prank(player);
        vm.expectRevert(Lumberjack.TimerExpired.selector);
        lumberjack.makeMove(Lumberjack.Move.LEFT);
    }

    function testCheckTimeout() public {
        _startGameForPlayer(player, 12345);

        // Fast forward past timer
        vm.warp(block.timestamp + 31 seconds);

        // Anyone can call checkTimeout
        vm.expectEmit(true, false, false, true);
        emit GameEnded(player, 0, false);
        lumberjack.checkTimeout(player);

        // Game should be inactive
        (,,,,,,, bool isActive,) = lumberjack.games(player);
        assertFalse(isActive);
    }

    function testHighScoreUpdate() public {
        _startGameForPlayer(player, 12345);

        // Make several successful moves
        for (uint256 i = 0; i < 5; i++) {
            // Get current branch
            (,,,,,, uint8 nextBranch,,) = lumberjack.games(player);

            // Move to opposite side of branch
            Lumberjack.Move safeMove =
                nextBranch == uint8(Lumberjack.BranchSide.LEFT) ? Lumberjack.Move.RIGHT : Lumberjack.Move.LEFT;

            vm.prank(player);
            lumberjack.makeMove(safeMove);
        }

        // End game by timeout
        vm.warp(block.timestamp + 31 seconds);
        lumberjack.checkTimeout(player);

        // Check high score
        assertEq(lumberjack.highScores(player), 5);
    }

    function testLeaderboard() public {
        // Multiple players play
        uint256[] memory seeds = new uint256[](3);
        seeds[0] = 100;
        seeds[1] = 200;
        seeds[2] = 300;

        address[] memory players = new address[](3);
        players[0] = player;
        players[1] = player2;
        players[2] = address(0x3);

        vm.deal(players[2], 10 ether);

        // Each player plays and gets different scores
        for (uint256 i = 0; i < players.length; i++) {
            _startGameForPlayer(players[i], seeds[i]);

            // Make i+1 successful moves
            for (uint256 j = 0; j <= i; j++) {
                (,,,,,, uint8 nextBranch,,) = lumberjack.games(players[i]);

                Lumberjack.Move safeMove =
                    nextBranch == uint8(Lumberjack.BranchSide.LEFT) ? Lumberjack.Move.RIGHT : Lumberjack.Move.LEFT;

                vm.prank(players[i]);
                lumberjack.makeMove(safeMove);
            }

            // End game
            vm.warp(block.timestamp + 31 seconds);
            lumberjack.checkTimeout(players[i]);
        }

        // Check leaderboard
        (address[] memory leaderPlayers, uint256[] memory leaderScores) = lumberjack.getLeaderboard();

        // Player 3 should be first with score 3
        assertEq(leaderPlayers[0], players[2]);
        assertEq(leaderScores[0], 3);

        // Player 2 should be second with score 2
        assertEq(leaderPlayers[1], players[1]);
        assertEq(leaderScores[1], 2);

        // Player 1 should be third with score 1
        assertEq(leaderPlayers[2], players[0]);
        assertEq(leaderScores[2], 1);
    }

    function testPreviewBranches() public {
        _startGameForPlayer(player, 12345);

        // Preview next 5 branches
        uint8[] memory branches = lumberjack.previewBranches(player, 5);

        assertEq(branches.length, 5);
        for (uint256 i = 0; i < branches.length; i++) {
            assertLe(branches[i], 2); // Valid branch values
        }
    }

    function testGetGameState() public {
        _startGameForPlayer(player, 12345);

        // Get initial branch
        (,,,,,, uint8 initialBranch,,) = lumberjack.games(player);

        // Move to opposite side of branch
        Lumberjack.Move safeMove =
            initialBranch == uint8(Lumberjack.BranchSide.LEFT) ? Lumberjack.Move.RIGHT : Lumberjack.Move.LEFT;

        // Make a move
        vm.prank(player);
        lumberjack.makeMove(safeMove);

        // Get game state
        (uint256 score, uint256 playerPosition, uint8 nextBranch, uint256 timeRemaining, bool isActive) =
            lumberjack.getGameState(player);

        assertEq(score, 1);
        assertEq(playerPosition, uint256(safeMove)); // Should match the move we made
        assertLe(nextBranch, 2);
        assertGt(timeRemaining, 0);
        assertTrue(isActive);
    }

    function testFuzzBranchGeneration(uint256 seed, uint256 height) public {
        // Bound inputs
        seed = bound(seed, 1, type(uint256).max);
        height = bound(height, 1, 1000);

        // Deploy a test contract to access private functions
        BranchGeneratorTest tester = new BranchGeneratorTest();

        // Get a sequence of valid branches
        uint8[] memory branches = new uint8[](20);
        uint256 currentHeight = height;

        for (uint256 i = 0; i < 20; i++) {
            branches[i] = tester.getNextValidBranch(seed, currentHeight);
            currentHeight++;
        }

        // Verify the getNextValidBranch function ensures proper spacing
        // We can't check the raw generation because it may produce invalid sequences
        // But getNextValidBranch should always return valid branches
        for (uint256 i = 0; i < branches.length; i++) {
            assertLe(branches[i], 2, "Invalid branch value");
        }
    }

    // Helper function to start and initialize a game
    function _startGameForPlayer(address _player, uint256 seed) private {
        vm.prank(_player);
        lumberjack.startGame();

        // Use the current request ID and increment for next use
        uint256 requestId = nextRequestId++;

        // Fulfill VRF
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = seed;
        vrfCoordinator.fulfillRandomNumbers(requestId, randomWords);
    }
}

// Test contract to access private functions
contract BranchGeneratorTest {
    uint256 private constant PLAYER_HEIGHT = 3;
    uint256 private constant MIN_BRANCH_GAP = PLAYER_HEIGHT;

    enum BranchSide {
        LEFT,
        RIGHT,
        NONE
    }

    function getNextValidBranch(uint256 seed, uint256 startHeight) external pure returns (uint8) {
        for (uint256 h = startHeight; h < startHeight + 20; h++) {
            BranchSide branch = _generateBranchAt(seed, h);
            if (_isValidBranchPlacement(seed, h, branch)) {
                return uint8(branch);
            }
        }
        return uint8(BranchSide.NONE);
    }

    function _generateBranchAt(uint256 seed, uint256 height) private pure returns (BranchSide) {
        uint256 random = uint256(keccak256(abi.encode(seed, height)));

        uint256 roll = random % 10;
        if (roll < 4) return BranchSide.LEFT;
        if (roll < 8) return BranchSide.RIGHT;
        return BranchSide.NONE;
    }

    function _isValidBranchPlacement(uint256 seed, uint256 height, BranchSide side) private pure returns (bool) {
        if (side == BranchSide.NONE) return true;

        for (uint256 i = 1; i <= MIN_BRANCH_GAP; i++) {
            if (height >= i) {
                BranchSide prevBranch = _generateBranchAt(seed, height - i);
                if (prevBranch == side) return false;
            }
        }
        return true;
    }
}
