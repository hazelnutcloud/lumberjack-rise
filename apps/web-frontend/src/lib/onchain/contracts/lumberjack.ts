import { riseTestnet } from 'viem/chains';

export const LUMBERJACK_CONTRACT = {
	abi: [
		{
			type: 'constructor',
			inputs: [{ name: '_vrfCoordinator', type: 'address', internalType: 'address' }],
			stateMutability: 'nonpayable'
		},
		{
			type: 'function',
			name: 'checkTimeout',
			inputs: [{ name: 'player', type: 'address', internalType: 'address' }],
			outputs: [],
			stateMutability: 'nonpayable'
		},
		{
			type: 'function',
			name: 'coordinator',
			inputs: [],
			outputs: [{ name: '', type: 'address', internalType: 'contract IVRFCoordinator' }],
			stateMutability: 'view'
		},
		{
			type: 'function',
			name: 'games',
			inputs: [{ name: '', type: 'address', internalType: 'address' }],
			outputs: [
				{ name: 'gameId', type: 'uint256', internalType: 'uint256' },
				{ name: 'randomSeed', type: 'uint256', internalType: 'uint256' },
				{ name: 'currentHeight', type: 'uint256', internalType: 'uint256' },
				{ name: 'playerPosition', type: 'uint256', internalType: 'uint256' },
				{ name: 'timerEnd', type: 'uint256', internalType: 'uint256' },
				{ name: 'timePerMove', type: 'uint256', internalType: 'uint256' },
				{ name: 'nextBranchSide', type: 'uint8', internalType: 'uint8' },
				{ name: 'isActive', type: 'bool', internalType: 'bool' },
				{ name: 'awaitingVRF', type: 'bool', internalType: 'bool' }
			],
			stateMutability: 'view'
		},
		{
			type: 'function',
			name: 'getGameState',
			inputs: [{ name: 'player', type: 'address', internalType: 'address' }],
			outputs: [
				{ name: 'score', type: 'uint256', internalType: 'uint256' },
				{ name: 'playerPosition', type: 'uint256', internalType: 'uint256' },
				{ name: 'nextBranch', type: 'uint8', internalType: 'uint8' },
				{ name: 'timeRemaining', type: 'uint256', internalType: 'uint256' },
				{ name: 'isActive', type: 'bool', internalType: 'bool' }
			],
			stateMutability: 'view'
		},
		{
			type: 'function',
			name: 'getLeaderboard',
			inputs: [],
			outputs: [
				{ name: '', type: 'address[]', internalType: 'address[]' },
				{ name: '', type: 'uint256[]', internalType: 'uint256[]' }
			],
			stateMutability: 'view'
		},
		{
			type: 'function',
			name: 'highScores',
			inputs: [{ name: '', type: 'address', internalType: 'address' }],
			outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
			stateMutability: 'view'
		},
		{
			type: 'function',
			name: 'leaderboardPlayers',
			inputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
			outputs: [{ name: '', type: 'address', internalType: 'address' }],
			stateMutability: 'view'
		},
		{
			type: 'function',
			name: 'leaderboardScores',
			inputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
			outputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
			stateMutability: 'view'
		},
		{
			type: 'function',
			name: 'makeMove',
			inputs: [{ name: 'move', type: 'uint8', internalType: 'enum Lumberjack.Move' }],
			outputs: [],
			stateMutability: 'nonpayable'
		},
		{
			type: 'function',
			name: 'previewBranches',
			inputs: [
				{ name: 'player', type: 'address', internalType: 'address' },
				{ name: 'count', type: 'uint256', internalType: 'uint256' }
			],
			outputs: [{ name: '', type: 'uint8[]', internalType: 'uint8[]' }],
			stateMutability: 'view'
		},
		{
			type: 'function',
			name: 'rawFulfillRandomNumbers',
			inputs: [
				{ name: 'requestId', type: 'uint256', internalType: 'uint256' },
				{ name: 'randomNumbers', type: 'uint256[]', internalType: 'uint256[]' }
			],
			outputs: [],
			stateMutability: 'nonpayable'
		},
		{
			type: 'function',
			name: 'requestIdToPlayer',
			inputs: [{ name: '', type: 'uint256', internalType: 'uint256' }],
			outputs: [{ name: '', type: 'address', internalType: 'address' }],
			stateMutability: 'view'
		},
		{ type: 'function', name: 'startGame', inputs: [], outputs: [], stateMutability: 'nonpayable' },
		{
			type: 'event',
			name: 'GameEnded',
			inputs: [
				{ name: 'player', type: 'address', indexed: true, internalType: 'address' },
				{ name: 'finalScore', type: 'uint256', indexed: false, internalType: 'uint256' },
				{ name: 'victory', type: 'bool', indexed: false, internalType: 'bool' }
			],
			anonymous: false
		},
		{
			type: 'event',
			name: 'GameStartRequested',
			inputs: [
				{ name: 'player', type: 'address', indexed: true, internalType: 'address' },
				{ name: 'requestId', type: 'uint256', indexed: false, internalType: 'uint256' }
			],
			anonymous: false
		},
		{
			type: 'event',
			name: 'GameStarted',
			inputs: [
				{ name: 'player', type: 'address', indexed: true, internalType: 'address' },
				{ name: 'gameId', type: 'uint256', indexed: false, internalType: 'uint256' },
				{ name: 'randomSeed', type: 'uint256', indexed: false, internalType: 'uint256' }
			],
			anonymous: false
		},
		{
			type: 'event',
			name: 'MoveMade',
			inputs: [
				{ name: 'player', type: 'address', indexed: true, internalType: 'address' },
				{ name: 'move', type: 'uint8', indexed: false, internalType: 'enum Lumberjack.Move' },
				{ name: 'score', type: 'uint256', indexed: false, internalType: 'uint256' },
				{ name: 'nextBranch', type: 'uint8', indexed: false, internalType: 'uint8' },
				{ name: 'timerEnd', type: 'uint256', indexed: false, internalType: 'uint256' }
			],
			anonymous: false
		},
		{ type: 'error', name: 'GameAlreadyActive', inputs: [] },
		{ type: 'error', name: 'InvalidRequestId', inputs: [] },
		{ type: 'error', name: 'NoActiveGame', inputs: [] },
		{ type: 'error', name: 'NoRandomNumbers', inputs: [] },
		{ type: 'error', name: 'OnlyVRFCoordinator', inputs: [] },
		{ type: 'error', name: 'TimerExpired', inputs: [] }
	],
	[riseTestnet.id]: {
		address: '0x2317359a678736aafae4c7387ac2c3a5089e7b6e'
	}
} as const;
