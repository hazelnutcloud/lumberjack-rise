import { GameObject, SpriteObject } from './object.svelte';
import type { GameContext } from './types';

export class Lumberjack extends SpriteObject {
	position: [number, number, number] = [-0.7, -2.1, -0.2];
	scale: [number, number, number] = [0.8, 0.8, 0.8];
	texture = this.ctx.textureLoader.load('/sprites/lumberjack.png');
	abortController = new AbortController();
	side: 'left' | 'right' = 'left';

	constructor(ctx: GameContext) {
		super(ctx);

		ctx.eventBus.on('MoveRight', () => this.handlePlayerMove('right'), {
			signal: this.abortController.signal
		});

		ctx.eventBus.on('MoveLeft', () => this.handlePlayerMove('left'), {
			signal: this.abortController.signal
		});
	}

	handlePlayerMove(direction: 'left' | 'right') {
		if (this.ctx.store.get('GameOver')) return;
		this.position[0] = direction === 'left' ? -0.7 : 0.7;
		this.texture.update((texture) => {
			if (texture) {
				texture.repeat.x = direction === 'left' ? 1 : -1;
				texture.offset.x = direction === 'left' ? 0 : 1;
			}
			return texture;
		});
		this.side = direction;
	}

	destroy() {
		this.abortController.abort();
	}
}
