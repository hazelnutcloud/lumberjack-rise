import type { AsyncWritable } from '@threlte/core';
import type { Texture } from 'three';
import type { GameContext } from './types';

export abstract class GameObject {
	abstract position: [number, number, number];
	abstract scale: [number, number, number];
	children: GameObject[];
	ctx: GameContext;
	texture?: AsyncWritable<Texture>;

	constructor(ctx: GameContext) {
		this.children = [];
		this.ctx = ctx;
	}

	async init(): Promise<void> {
		await Promise.all([this.texture, ...this.children.map((child) => child.init())]);
	}

	destroy(): void {}

	update?: (delta: number) => void;
}
