# Lumberjack Smart Contracts

Lumberjack is an on-chain reflex game where players chop down an infinite tree while avoiding branches.

## Game Mechanics

- Players start on the left side of the tree
- Each move (left/right) chops the tree and moves the player
- Branches appear on either side - hitting one ends the game
- Timer counts down - make moves to add time (capped at 5 seconds max)
- Fixed time bonus per move (1 second)
- Infinite gameplay with deterministic branch generation

## Architecture

### Core Contract: `Lumberjack.sol`

- **Fast VRF Integration**: Uses RISE Chain's Fast VRF for unique random seeds
- **On-Demand Branch Generation**: Calculates branches as needed (gas efficient)
- **Timer Cap System**: Timer capped at 5 seconds with 1 second bonus per move
- **Leaderboard**: Tracks top 10 scores globally

### Key Features

1. **Infinite Tree**: No height limit, branches generated deterministically
2. **Fair Randomness**: Fast VRF ensures unpredictable but verifiable games
3. **Gas Optimized**: Only stores current game state, not entire tree
4. **Player Safety**: Minimum 3-block gap between branches on same side

## Development

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js (for package scripts)

### Setup

```bash
# Install dependencies
forge install

# Run tests
forge test

# Run tests with gas reporting
forge test --gas-report

# Deploy to local network
forge script script/Deploy.s.sol --rpc-url localhost --broadcast
```

### Testing

```bash
# Run all tests
forge test

# Run specific test
forge test --match-test testStartGame

# Run with verbosity
forge test -vvv

# Gas snapshot
forge snapshot
```

### Deployment

Deploy the contract to RISE Chain:

```bash
forge script script/Deploy.s.sol --rpc-url https://testnet.risechain.xyz --private-key <PRIVATE_KEY> --broadcast
```

The contract will automatically use the Fast VRF Coordinator at `0x9d57aB4517ba97349551C876a01a7580B1338909`

## Contract Addresses

| Network    | Address | VRF Coordinator                            |
| ---------- | ------- | ------------------------------------------ |
| RISE Chain | TBD     | 0x9d57aB4517ba97349551C876a01a7580B1338909 |

## Gas Costs

- Start Game: ~124k gas (includes VRF request)
- Make Move: ~66k gas
- End Game: ~30k gas

## Security Considerations

- VRF callback restricted to Fast VRF Coordinator
- No reentrancy vulnerabilities
- Deterministic branch generation prevents manipulation
- Timer prevents indefinite games
- ECDSA signature verification ensures random number integrity
