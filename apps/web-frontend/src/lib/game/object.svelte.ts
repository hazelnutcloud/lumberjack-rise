import type { AsyncWritable } from '@threlte/core';
import type { Texture } from 'three';
import type { GameContext } from './types';

export abstract class GameObject {
	position: [number, number, number] = $state([0, 0, 0]);
	scale: [number, number, number] = $state([1, 1, 1]);
	children: GameObject[] = $state([]);
	ctx: GameContext;
	texture?: AsyncWritable<Texture>;

	constructor(ctx: GameContext) {
		this.ctx = ctx;
	}

	async init(): Promise<void> {
		await Promise.all([this.texture, ...this.children.map((child) => child.init())]);
	}

	destroy(): void {}

	update?: (delta: number) => void;
}
