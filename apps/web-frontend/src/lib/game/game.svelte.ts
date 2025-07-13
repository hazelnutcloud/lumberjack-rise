import Emittery from 'emittery';
import type { GameObject } from './object.svelte';
import { Tree } from './tree.svelte';
import { Lumberjack } from './player.svelte';
import type { EventBus, GameContext, InputMap } from './types';
import type { useLoader } from '@threlte/core';
import type { TextureLoader } from 'three';
import { Timer } from './timer-obj.svelte';

export const inputMap = {
	'keydown:ArrowRight': 'MoveRight',
	'keydown:ArrowLeft': 'MoveLeft',
	'keydown:Enter': 'StartGame'
} as const satisfies InputMap;

export class Game {
	scene: GameObject[];
	eventBus: EventBus;
	inputMap: InputMap;

	constructor(textureLoader: ReturnType<typeof useLoader<typeof TextureLoader>>) {
		this.eventBus = new Emittery();
		const ctx = {
			eventBus: this.eventBus,
			remove: (obj) => this.removeObj(obj),
			textureLoader,
			store: new Map()
		} satisfies GameContext;
		const player = new Lumberjack(ctx);
		this.scene = $state([player, new Tree(ctx, player), new Timer(ctx, 5000)]);
		this.inputMap = inputMap;
	}

	update(delta: number) {
		for (const obj of this.scene) {
			this.updateObject(obj, delta);
		}
	}

	updateObject(obj: GameObject, delta: number) {
		obj.update(delta);
		for (const child of obj.children) {
			this.updateObject(child, delta);
		}
	}

	async init() {
		await Promise.all(this.scene.map((obj) => obj.init()));
	}

	handleKeydown(evt: KeyboardEvent) {
		const command = this.inputMap[`keydown:${evt.key}`];
		if (!command) return;
		this.eventBus.emit(command, evt);
	}

	handleKeyup(evt: KeyboardEvent) {
		const command = this.inputMap[`keyup:${evt.key}`];
		if (!command) return;
		this.eventBus.emit(command, evt);
	}

	removeObj(obj: GameObject) {
		const idx = this.scene.findIndex((sceneObj) => sceneObj === obj);
		if (idx === -1) return;
		this.scene.splice(idx, 1);
		obj.destroy();
	}
}
