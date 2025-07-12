import { useTexture } from '@threlte/extras';
import { GameObject } from './object.svelte';
import type { GameContext } from './types';

export class Tree extends GameObject {
	position: [number, number, number] = [0, 0, 0];
	scale: [number, number, number] = [1, 1, 1];
	height = 10;

	constructor(ctx: GameContext) {
		super(ctx);

		const branches = Array.from(
			{ length: this.height },
			(_, i) => new Branch(this.ctx, [-0.5, -1.4 + i * 0.6, 0])
		);
		const trunks = Array.from(
			{ length: this.height },
			(_, i) => new Trunk(this.ctx, [0, -2 + i * 0.6, 0])
		);

		this.children = branches.concat(trunks);
	}
}

export class Trunk extends GameObject {
	texture = useTexture('/sprites/tree-trunk.png');
	position: [number, number, number];
	scale: [number, number, number] = [1, 1, 1];

	constructor(ctx: GameContext, position: [number, number, number]) {
		super(ctx);
		this.position = $state(position);
	}
}

export class Branch extends GameObject {
	texture = useTexture('/sprites/tree-branch.png');
	position: [number, number, number];
	scale: [number, number, number] = [1, 1, 1];

	constructor(ctx: GameContext, position: [number, number, number]) {
		super(ctx);
		this.position = $state(position);
	}
}
