import type { WebSocket } from 'partysocket';
import type { GameContext } from './types';
import type { RelaySchema, ServerSchema } from 'auth-server/relay';
import {
	createPublicClient,
	decodeErrorResult,
	encodeFunctionData,
	type Hex,
	type PublicClient,
	webSocket
} from 'viem';
import { LUMBERJACK_CONTRACT } from '$lib/onchain/contracts/lumberjack';
import { riseTestnet } from 'viem/chains';

export class OnchainSync {
	ctx: GameContext;
	requestId: number;
	onchainClient: PublicClient;
	ws?: WebSocket;

	constructor(ctx: GameContext) {
		this.ctx = ctx;
		this.requestId = 0;
		this.setupInputListeners();
		this.onchainClient = createPublicClient({
			chain: riseTestnet,
			transport: webSocket()
		});
		this.setupOnchainListeners();
	}

	setupInputListeners() {
		this.ctx.eventBus.on('MoveRight', () => this.handleMove('right'));
		this.ctx.eventBus.on('MoveLeft', () => this.handleMove('left'));
		this.ctx.eventBus.on('RawStartGame', () => this.handleGameStart());
	}

	setupOnchainListeners() {
		this.onchainClient.watchContractEvent({
			abi: LUMBERJACK_CONTRACT.abi,
			address: LUMBERJACK_CONTRACT[11155931].address,
			eventName: 'MoveMade',
			onLogs: (logs) => {
				for (const log of logs) {
					if (log.args.move === undefined) continue;
					// this.ctx.eventBus.emit(log.args.move === 0 ? 'MoveLeft' : 'MoveRight');
				}
			}
		});
		this.onchainClient.watchContractEvent({
			abi: LUMBERJACK_CONTRACT.abi,
			address: LUMBERJACK_CONTRACT[11155931].address,
			eventName: 'GameStarted',
			onLogs: (logs) => {
				for (const log of logs) {
					if (log.args.randomSeed === undefined) continue;
					this.ctx.eventBus.emit('StartGame', log.args.randomSeed);
				}
			}
		});
		this.onchainClient.watchContractEvent({
			abi: LUMBERJACK_CONTRACT.abi,
			address: LUMBERJACK_CONTRACT[11155931].address,
			eventName: 'GameEnded',
			onLogs: (logs) => {
				for (const log of logs) {
					if (log.args.player === undefined) continue;
					this.ctx.eventBus.emit('GameOver');
				}
			}
		});
	}

	setupRelayListeners() {
		if (!this.ws) return;

		this.ws.onmessage = (msg) => {
			console.log(msg.data);
			const packet = JSON.parse(msg.data) as ServerSchema;

			if (packet.type === 'error') {
				console.error(packet.message);
			}
		};
	}

	handleGameStart() {
		if (!this.ws) return;
		const input = encodeFunctionData({
			abi: LUMBERJACK_CONTRACT.abi,
			functionName: 'startGame',
			args: []
		});
		const packet = {
			id: this.requestId++,
			type: 'sendTransaction',
			input,
			to: LUMBERJACK_CONTRACT[11155931].address,
			value: '0x0'
		} satisfies typeof RelaySchema.ClientSchema.infer;
		this.ws.send(JSON.stringify(packet));
		this.ctx.eventBus.emit('GameLoading');
	}

	handleMove(direction: 'left' | 'right') {
		if (!this.ws) return;
		const input = encodeFunctionData({
			abi: LUMBERJACK_CONTRACT.abi,
			functionName: 'makeMove',
			args: direction === 'left' ? [0] : [1]
		});
		const packet = {
			id: this.requestId++,
			type: 'sendTransaction',
			input,
			to: LUMBERJACK_CONTRACT[11155931].address,
			value: '0x0'
		} satisfies typeof RelaySchema.ClientSchema.infer;
		this.ws.send(JSON.stringify(packet));
	}

	setWs(ws: WebSocket | undefined) {
		this.ws = ws;
	}
}
