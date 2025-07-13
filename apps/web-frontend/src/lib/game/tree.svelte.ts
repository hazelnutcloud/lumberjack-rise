import { GameObject, SpriteObject } from './object.svelte';
import type { GameContext } from './types';
import { randomBigInt256 } from './utils/rng';
import { encodeAbiParameters, hexToBigInt, keccak256 } from 'viem';
import type { AsyncWritable } from '@threlte/core';
import type { Texture } from 'three';
import type { Lumberjack } from './player.svelte';

type BranchPosition = 'left' | 'right' | 'none';

export class Tree extends GameObject {
	BUFFER_HEIGHT = 10;
	randomNumber = randomBigInt256();

	constructor(ctx: GameContext, player: Lumberjack) {
		super(ctx);

		const trunks = Array.from({ length: this.BUFFER_HEIGHT }, (_, i) => new Trunk(this.ctx, i));
		const branchContainer = new BranchContainer(ctx, {
			bufferHeight: this.BUFFER_HEIGHT,
			randomNumber: this.randomNumber,
			player
		});

		this.children = [...trunks, branchContainer];
	}
}

export class Trunk extends SpriteObject {
	texture = this.ctx.textureLoader.load('/sprites/tree-trunk.png');

	constructor(ctx: GameContext, height: number) {
		super(ctx);
		this.position = [0, -2 + height * 0.6, 0];
	}
}

export class BranchContainer extends GameObject {
	currentHeight = 1;
	bufferHeight: number;
	randomNumber: bigint;
	branches: (Branch | null)[] = [];
	abortController: AbortController;

	constructor(
		ctx: GameContext,
		params: { randomNumber: bigint; bufferHeight: number; player: Lumberjack }
	) {
		super(ctx);

		this.bufferHeight = params.bufferHeight;
		this.randomNumber = params.randomNumber;

		for (this.currentHeight; this.currentHeight <= this.bufferHeight; this.currentHeight++) {
			const position = this.getBranchPosition(this.currentHeight);
			if (position === 'none') {
				this.branches.push(null);
			} else {
				this.branches.push(
					new Branch(this.ctx, {
						height: this.currentHeight,
						position
					})
				);
			}
		}

		this.children = this.branches.filter((b) => b !== null);

		this.abortController = new AbortController();
		this.ctx.eventBus.on('MoveRight', () => this.handlePlayerMove('right'), {
			signal: this.abortController.signal
		});
		this.ctx.eventBus.on('MoveLeft', () => this.handlePlayerMove('left'), {
			signal: this.abortController.signal
		});
	}

	handlePlayerMove(direction: 'left' | 'right') {
		if (this.ctx.store.get('GameOver')) return;
		const nextPosition = this.getBranchPosition(this.currentHeight);
		const removedBranch = this.branches.shift();
		this.branches.push(
			nextPosition === 'none'
				? null
				: new Branch(this.ctx, { height: this.currentHeight, position: nextPosition })
		);
		this.currentHeight += 1;
		const nextBranch = this.branches[0];
		if (nextBranch) {
			if (nextBranch.branchPosition === direction) {
				this.ctx.eventBus.emit('GameOver');
				this.ctx.store.set('GameOver', true);
			}
			nextBranch.destroy();
		}
		this.children = this.branches.filter((b) => b !== null);
		this.position[1] -= 0.6;
	}

	getBranchPosition(height: number) {
		if (height === 1) return 'none';
		const branch = this.generateBranchAt(height);

		if (height > 3) {
			for (let i = 1; i <= 3; i++) {
				const prevBranch = this.generateBranchAt(height - i);
				if (prevBranch !== branch) {
					return branch;
				}
			}
			return 'none';
		}

		return branch;
	}

	generateBranchAt(height: number) {
		const random = hexToBigInt(
			keccak256(
				encodeAbiParameters(
					[{ type: 'uint256' }, { type: 'uint256' }],
					[this.randomNumber, BigInt(height)]
				)
			)
		);

		const roll = random % 10n;

		if (roll < 5) {
			return 'left';
		} else {
			return 'right';
		}
	}

	destroy(): void {
		this.abortController.abort();
	}
}

export class Branch extends SpriteObject {
	texture: AsyncWritable<Texture>;
	position: [number, number, number];
	branchPosition: BranchPosition;

	constructor(ctx: GameContext, params: { height: number; position: BranchPosition }) {
		super(ctx);
		const { height, position } = params;
		this.position = $state<[number, number, number]>([
			position === 'left' ? -0.5 : 0.5,
			-2.7 + height * 0.6,
			-0.1
		]);
		this.texture =
			position === 'right'
				? ctx.textureLoader.load('/sprites/tree-branch-right.png')
				: ctx.textureLoader.load('/sprites/tree-branch.png');
		this.branchPosition = params.position;
	}
}
