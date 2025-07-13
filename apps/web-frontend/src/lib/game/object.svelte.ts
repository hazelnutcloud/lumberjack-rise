import type { AsyncWritable } from '@threlte/core';
import type { Texture } from 'three';
import type { GameContext, Vector3 } from './types';
import type { Component } from 'svelte';

export abstract class GameObject {
	position: Vector3 = $state([0, 0, 0]);
	scale: Vector3 = $state([1, 1, 1]);
	children: GameObject[] = $state([]);
	ctx: GameContext;

	constructor(ctx: GameContext) {
		this.ctx = ctx;
	}

	async init(): Promise<void> {
		await Promise.all(this.children.map((child) => child.init()));
	}

	destroy(): void {}

	update(delta: number): void {}
}

export abstract class SpriteObject extends GameObject {
	abstract texture: AsyncWritable<Texture>;

	async init(): Promise<void> {
		await Promise.all([super.init(), this.texture]);
	}
}

export abstract class HTMLObject extends GameObject {
	abstract component: Component<any>;
	abstract args: Record<string, any>;
}
