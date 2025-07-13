import { GameObject } from './object.svelte';
import type { GameContext } from './types';

export class Lumberjack extends GameObject {
	position = $state<[number, number, number]>([-0.7, -2.1, -0.2]);
	scale = $state<[number, number, number]>([0.8, 0.8, 0.8]);
	texture = this.ctx.textureLoader.load('/sprites/lumberjack.png');
	abortController = new AbortController();
	side: 'left' | 'right' = 'left';

	constructor(ctx: GameContext) {
		super(ctx);

		ctx.eventBus.on(
			'MoveRight',
			() => {
				this.position[0] = 0.7;
				this.texture.update((texture) => {
					if (texture) {
						texture.repeat.x = -1;
						texture.offset.x = 1;
					}
					return texture;
				});
				this.side = 'left';
			},
			{ signal: this.abortController.signal }
		);

		ctx.eventBus.on(
			'MoveLeft',
			() => {
				this.position[0] = -0.7;
				this.texture.update((texture) => {
					if (texture) {
						texture.repeat.x = 1;
						texture.offset.x = 0;
					}
					return texture;
				});
				this.side = 'right';
			},
			{ signal: this.abortController.signal }
		);
	}

	destroy() {
		this.abortController.abort();
	}
}
