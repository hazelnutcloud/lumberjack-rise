// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Lumberjack is VRFConsumerBaseV2Plus {
    // Custom errors
    error NoActiveGame();
    error GameAlreadyActive();
    error TimerExpired();
    error InvalidRequestId();
    error Unauthorized();

    // Game constants
    uint256 private constant PLAYER_HEIGHT = 3;
    uint256 private constant MIN_BRANCH_GAP = PLAYER_HEIGHT;
    uint256 private constant INITIAL_TIMER = 5 seconds;
    uint256 private constant TIME_PER_CHOP = 1 seconds;
    uint256 private constant LEADERBOARD_SIZE = 10;

    // VRF configuration
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Enums
    enum Move {
        LEFT,
        RIGHT
    }
    enum BranchSide {
        LEFT,
        RIGHT,
        NONE
    }

    // Game state for each player
    struct GameState {
        uint256 gameId;
        uint256 randomSeed;
        uint256 currentHeight;
        uint256 playerPosition;
        uint256 timerEnd;
        uint256 timePerMove;
        uint8 nextBranchSide;
        bool isActive;
        bool awaitingVRF;
    }

    // State variables
    mapping(address => GameState) public games;
    mapping(address => uint256) public highScores;
    mapping(uint256 => address) public requestIdToPlayer;

    // Leaderboard
    address[] public leaderboardPlayers;
    uint256[] public leaderboardScores;

    // Events
    event GameStartRequested(address indexed player, uint256 requestId);
    event GameStarted(address indexed player, uint256 gameId, uint8 firstBranch);
    event MoveMade(address indexed player, Move move, uint256 score, uint8 nextBranch, uint256 timerEnd);
    event GameEnded(address indexed player, uint256 finalScore, bool victory);

    constructor(address vrfCoordinator, uint256 subscriptionId, bytes32 keyHash, uint32 callbackGasLimit)
        VRFConsumerBaseV2Plus(vrfCoordinator)
    {
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;

        // Initialize empty leaderboard
        leaderboardPlayers = new address[](LEADERBOARD_SIZE);
        leaderboardScores = new uint256[](LEADERBOARD_SIZE);
    }

    // Start a new game
    function startGame() external {
        GameState storage game = games[msg.sender];
        if (game.isActive) revert GameAlreadyActive();

        // Request random seed from Chainlink VRF
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );

        game.awaitingVRF = true;
        requestIdToPlayer[requestId] = msg.sender;

        emit GameStartRequested(msg.sender, requestId);
    }

    // VRF callback
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        address player = requestIdToPlayer[requestId];
        if (player == address(0)) revert InvalidRequestId();

        _initializeGame(player, randomWords[0]);
        delete requestIdToPlayer[requestId];
    }

    // Initialize game with random seed
    function _initializeGame(address player, uint256 randomSeed) private {
        GameState storage game = games[player];

        game.gameId = uint256(keccak256(abi.encode(player, block.timestamp)));
        game.randomSeed = randomSeed;
        game.currentHeight = 0;
        game.playerPosition = 0; // Start on left
        game.timerEnd = block.timestamp + INITIAL_TIMER;
        game.timePerMove = TIME_PER_CHOP;
        game.isActive = true;
        game.awaitingVRF = false;

        // Calculate first branch
        game.nextBranchSide = uint8(_getNextValidBranch(randomSeed, 1));

        emit GameStarted(player, game.gameId, game.nextBranchSide);
    }

    // Make a move (chop the tree)
    function makeMove(Move move) external {
        GameState storage game = games[msg.sender];
        if (!game.isActive) revert NoActiveGame();
        if (block.timestamp > game.timerEnd) {
            _endGame(msg.sender);
            revert TimerExpired();
        }

        // Check collision with current branch
        if (
            (move == Move.LEFT && game.nextBranchSide == uint8(BranchSide.LEFT))
                || (move == Move.RIGHT && game.nextBranchSide == uint8(BranchSide.RIGHT))
        ) {
            // Game over - collision
            _endGame(msg.sender);
            emit GameEnded(msg.sender, game.currentHeight, false);
            return;
        }

        // Successful move
        game.playerPosition = uint256(move);
        game.currentHeight++;

        // Update timer with dynamic difficulty
        game.timerEnd = block.timestamp + TIME_PER_CHOP;

        // Calculate next branch
        uint256 nextBranchHeight = game.currentHeight + 1;
        game.nextBranchSide = uint8(_getNextValidBranch(game.randomSeed, nextBranchHeight));

        emit MoveMade(msg.sender, move, game.currentHeight, game.nextBranchSide, game.timerEnd);
    }

    // Check and handle timeout
    function checkTimeout(address player) external {
        GameState storage game = games[player];
        if (!game.isActive) revert NoActiveGame();
        if (block.timestamp <= game.timerEnd) return;

        _endGame(player);
        emit GameEnded(player, game.currentHeight, false);
    }

    // End game and update scores
    function _endGame(address player) private {
        GameState storage game = games[player];
        uint256 score = game.currentHeight;
        game.isActive = false;

        // Update high score
        if (score > highScores[player]) {
            highScores[player] = score;
            _updateLeaderboard(player, score);
        }
    }

    // Update leaderboard
    function _updateLeaderboard(address player, uint256 score) private {
        // Find position in leaderboard
        uint256 position = LEADERBOARD_SIZE;
        for (uint256 i = 0; i < LEADERBOARD_SIZE; i++) {
            if (score > leaderboardScores[i]) {
                position = i;
                break;
            }
        }

        if (position < LEADERBOARD_SIZE) {
            // Shift lower scores down
            for (uint256 i = LEADERBOARD_SIZE - 1; i > position; i--) {
                leaderboardPlayers[i] = leaderboardPlayers[i - 1];
                leaderboardScores[i] = leaderboardScores[i - 1];
            }

            // Insert new score
            leaderboardPlayers[position] = player;
            leaderboardScores[position] = score;
        }
    }

    // Generate branch for a specific height
    function _generateBranchAt(uint256 seed, uint256 height) private pure returns (BranchSide) {
        uint256 random = uint256(keccak256(abi.encode(seed, height)));

        // 40% left, 40% right, 20% none for variety
        uint256 roll = random % 10;
        if (roll < 4) return BranchSide.LEFT;
        if (roll < 8) return BranchSide.RIGHT;
        return BranchSide.NONE;
    }

    // Check if branch placement is valid
    function _isValidBranchPlacement(uint256 seed, uint256 height, BranchSide side) private pure returns (bool) {
        if (side == BranchSide.NONE) return true;

        // Check previous branches on same side within PLAYER_HEIGHT distance
        for (uint256 i = 1; i <= MIN_BRANCH_GAP; i++) {
            if (height >= i) {
                BranchSide prevBranch = _generateBranchAt(seed, height - i);
                if (prevBranch == side) return false;
            }
        }
        return true;
    }

    // Get next valid branch
    function _getNextValidBranch(uint256 seed, uint256 startHeight) private pure returns (BranchSide) {
        for (uint256 h = startHeight; h < startHeight + 20; h++) {
            BranchSide branch = _generateBranchAt(seed, h);
            if (_isValidBranchPlacement(seed, h, branch)) {
                return branch;
            }
        }
        return BranchSide.NONE; // Fallback
    }

    // Dynamic difficulty - decrease time as score increases
    function _getTimePerMove(uint256 score) private pure returns (uint256) {
        if (score < 50) return 2 seconds;
        if (score < 100) return 1500; // 1.5 seconds
        if (score < 200) return 1 seconds;
        return 500; // 0.5 seconds
    }

    // View functions
    function getGameState(address player)
        external
        view
        returns (uint256 score, uint256 playerPosition, uint8 nextBranch, uint256 timeRemaining, bool isActive)
    {
        GameState memory game = games[player];
        score = game.currentHeight;
        playerPosition = game.playerPosition;
        nextBranch = game.nextBranchSide;
        timeRemaining = game.timerEnd > block.timestamp ? game.timerEnd - block.timestamp : 0;
        isActive = game.isActive && block.timestamp <= game.timerEnd;
    }

    // Preview upcoming branches
    function previewBranches(address player, uint256 count) external view returns (uint8[] memory) {
        GameState memory game = games[player];
        if (!game.isActive) revert NoActiveGame();

        uint8[] memory branches = new uint8[](count);
        for (uint256 i = 0; i < count; i++) {
            branches[i] = uint8(_getNextValidBranch(game.randomSeed, game.currentHeight + i + 1));
        }
        return branches;
    }

    // Get leaderboard
    function getLeaderboard() external view returns (address[] memory, uint256[] memory) {
        return (leaderboardPlayers, leaderboardScores);
    }
}
