# Lumberjack Rise

A high-speed blockchain reflex game built on [RISE Chain](https://docs.risechain.com/getting-started/introduction.html) to demonstrate the chain's performance capabilities and serve as a testbed for RISE Wallet - RISE Chain's official wallet provider powered by seamless social logins and passkeys.

## 🎮 Game Overview

Lumberjack Rise is an on-chain adaptation of the classic lumberjack reflex game where players:

- Chop down an infinite tree while avoiding branches
- Start with a 5-second timer that increases with each successful chop
- Compete for high scores on a global leaderboard
- Experience true randomness powered by RISE Chain's Fast VRF

## 🏗️ Architecture

This monorepo contains three main components:

### 1. Smart Contracts (`packages/contracts/`)

- **Lumberjack.sol**: Core game logic with Fast VRF integration
- Gas-optimized for infinite gameplay
- Deterministic branch generation with player safety guarantees
- Global leaderboard tracking top 10 scores

### 2. Auth Server (`apps/auth-server/`)

- Cloudflare Workers-based authentication service
- OpenAuth integration for social logins
- Currently supports Discord authentication
- Foundation for future RISE Wallet integration

### 3. Web Frontend (`apps/web-frontend/`)

- SvelteKit application with Tailwind CSS
- Cloudflare Pages deployment
- Seamless authentication flow
- Game interface (in development)

## 🚀 Getting Started

### Prerequisites

- [Bun](https://bun.sh/) (package manager)
- [Foundry](https://book.getfoundry.sh/getting-started/installation) (for smart contract development)
- Node.js 18+

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/lumberjack-rise.git
cd lumberjack-rise

# Install dependencies
bun install

# Install Foundry dependencies for contracts
cd packages/contracts
forge install
cd ../..
```

### Development

Run all services locally:

```bash
bun dev
```

This starts:

- Auth server at `http://localhost:8787`
- Web frontend at `http://localhost:5173`

#### Individual Services

```bash
# Auth server only
bun --filter auth-server dev

# Web frontend only
bun --filter web-frontend dev

# Smart contract tests
cd packages/contracts
forge test
```

## 🔧 Configuration

### Environment Variables

Create `.env` files in respective app directories:

**`apps/auth-server/.env`**

```env
# Add your environment variables here
```

**`apps/web-frontend/.env`**

```env
# Add your environment variables here
```

### Smart Contract Deployment

Deploy to RISE Chain:

```bash
cd packages/contracts
forge script script/Deploy.s.sol --rpc-url https://risechain.xyz --private-key <PRIVATE_KEY> --broadcast
```

## 🎯 Roadmap

- [x] Core game smart contract
- [x] Discord authentication
- [x] Basic web interface
- [ ] Game UI implementation
- [ ] Passkey authentication
- [ ] Google OAuth integration
- [ ] X.com (Twitter) OAuth integration
- [ ] RISE Wallet integration
- [ ] Mobile responsive design
- [ ] Real-time leaderboard updates
- [ ] Tournament mode

## 🛠️ Tech Stack

- **Blockchain**: RISE Chain with Fast VRF
- **Smart Contracts**: Solidity, Foundry
- **Backend**: Cloudflare Workers, Hono, Drizzle ORM
- **Frontend**: SvelteKit, Tailwind CSS, Vite
- **Authentication**: OpenAuth
- **Infrastructure**: Cloudflare Pages, Cloudflare Workers
- **Development**: Bun, mprocs

## 📊 Gas Costs

- Start Game: ~124k gas (includes VRF request)
- Make Move: ~66k gas
- End Game: ~30k gas

## 🤝 Contributing

We welcome contributions! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [RISE Chain Documentation](https://docs.risechain.com/getting-started/introduction.html)
- [RISE Chain Community](https://docs.risechain.com/getting-started/introduction.html)

## 🙏 Acknowledgments

- RISE Chain team for the high-performance blockchain infrastructure
- OpenAuth for seamless authentication solutions
- Cloudflare for edge computing platform
