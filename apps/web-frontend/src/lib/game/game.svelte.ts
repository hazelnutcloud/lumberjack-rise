import Emittery from 'emittery';
import type { GameObject } from './object.svelte';
import { Tree } from './tree.svelte';
import { Lumberjack } from './player.svelte';
import type { EventBus, GameContext, InputMap } from './types';
import type { useLoader } from '@threlte/core';
import type { TextureLoader } from 'three';

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
			textureLoader
		} satisfies GameContext;
		this.scene = $state([new Lumberjack(ctx), new Tree(ctx)]);
		this.inputMap = inputMap;
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
