// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Fast VRF interfaces
interface IVRFConsumer {
    function rawFulfillRandomNumbers(uint256 requestId, uint256[] memory randomNumbers) external;
}

interface IVRFCoordinator {
    function requestRandomNumbers(uint32 numNumbers, uint256 clientSeed) external returns (uint256 requestId);

    function getClientSeed(uint256 requestId) external view returns (uint256);

    function fulfilled(uint256 requestId) external view returns (bool);
}

contract Lumberjack is IVRFConsumer {
    // Custom errors
    error NoActiveGame();
    error GameAlreadyActive();
    error TimerExpired();
    error InvalidRequestId();
    error OnlyVRFCoordinator();
    error NoRandomNumbers();

    // Game constants
    uint256 private constant INITIAL_TIMER = 5 seconds;
    uint256 private constant TIME_PER_CHOP = 1 seconds;
    uint256 private constant LEADERBOARD_SIZE = 10;

    // VRF Coordinator on RISE Chain
    IVRFCoordinator public immutable coordinator;

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

    constructor(address _vrfCoordinator) {
        coordinator = IVRFCoordinator(_vrfCoordinator);

        // Initialize empty leaderboard
        leaderboardPlayers = new address[](LEADERBOARD_SIZE);
        leaderboardScores = new uint256[](LEADERBOARD_SIZE);
    }

    // Start a new game
    function startGame() external {
        GameState storage game = games[msg.sender];
        if (game.isActive) revert GameAlreadyActive();

        // Request random seed from Fast VRF
        // Use blockhash as client seed for additional entropy
        uint256 clientSeed = uint256(blockhash(block.number - 1));
        uint256 requestId = coordinator.requestRandomNumbers(1, clientSeed);

        game.awaitingVRF = true;
        requestIdToPlayer[requestId] = msg.sender;

        emit GameStartRequested(msg.sender, requestId);
    }

    // VRF callback - called by VRF Coordinator
    function rawFulfillRandomNumbers(uint256 requestId, uint256[] memory randomNumbers) external override {
        if (msg.sender != address(coordinator)) revert OnlyVRFCoordinator();
        if (randomNumbers.length == 0) revert NoRandomNumbers();

        address player = requestIdToPlayer[requestId];
        if (player == address(0)) revert InvalidRequestId();

        _initializeGame(player, randomNumbers[0]);
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

        // Update timer with fixed time for now
        if ((game.timerEnd + TIME_PER_CHOP - block.timestamp) <= INITIAL_TIMER) {
            game.timerEnd += TIME_PER_CHOP;
        }

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

        // 50% left, 50% right
        uint256 roll = random % 10;
        if (roll < 5) return BranchSide.LEFT;
        return BranchSide.RIGHT;
    }

    // Get next valid branch
    function _getNextValidBranch(uint256 seed, uint256 startHeight) private pure returns (BranchSide) {
        if (startHeight == 1) {
            return BranchSide.NONE;
        }
        
        BranchSide branch = _generateBranchAt(seed, startHeight);
        
        uint256 maxConsecutive = 3;
        
        if (startHeight <= maxConsecutive) return branch;
        
        for (uint256 i = 1; i <= maxConsecutive; i++) {
           BranchSide prevBranch = _generateBranchAt(seed, startHeight - i); 
           if (prevBranch != branch) {
               return branch;
           }
        }
        
        return BranchSide.NONE;
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
