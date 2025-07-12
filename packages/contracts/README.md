# Lumberjack Smart Contracts

Lumberjack is an on-chain reflex game where players chop down an infinite tree while avoiding branches.

## Game Mechanics

- Players start on the left side of the tree
- Each move (left/right) chops the tree and moves the player
- Branches appear on either side - hitting one ends the game
- Timer counts down - make moves to add time
- Difficulty increases with score (less time per move)
- Infinite gameplay with deterministic branch generation

## Architecture

### Core Contract: `Lumberjack.sol`

- **Chainlink VRF Integration**: Generates unique random seed for each game
- **On-Demand Branch Generation**: Calculates branches as needed (gas efficient)
- **Dynamic Difficulty**: Time per move decreases as score increases
- **Leaderboard**: Tracks top 10 scores globally

### Key Features

1. **Infinite Tree**: No height limit, branches generated deterministically
2. **Fair Randomness**: Chainlink VRF ensures unpredictable but verifiable games
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

1. Set up a Chainlink VRF subscription on your target network
2. Fund the subscription with LINK tokens
3. Deploy the contract:

```bash
forge script script/Deploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

4. Add the deployed contract as a consumer to your VRF subscription

## Contract Addresses

| Network          | Address | VRF Subscription |
| ---------------- | ------- | ---------------- |
| Sepolia          | TBD     | TBD              |
| Base Sepolia     | TBD     | TBD              |
| Arbitrum Sepolia | TBD     | TBD              |

## Gas Costs

- Start Game: ~150k gas (includes VRF request)
- Make Move: ~50k gas
- End Game: ~30k gas

## Security Considerations

- VRF callback restricted to Chainlink Coordinator
- No reentrancy vulnerabilities
- Deterministic branch generation prevents manipulation
- Timer prevents indefinite games
