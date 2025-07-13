import type { ComponentProps } from 'svelte';
import { HTMLObject } from './object.svelte';
import TimerComponent from './timer.svelte';
import type { GameContext } from './types';

export class Timer extends HTMLObject {
	position: [number, number, number] = [-0.4, -2.4, 1];
	component = TimerComponent;
	args: ComponentProps<typeof TimerComponent>;
	abortController = new AbortController();
	initialTime: number;

	constructor(ctx: GameContext, timeLeft: number) {
		super(ctx);
		this.args = $state({ timeLeft, gameOver: false });
		this.initialTime = timeLeft;

		ctx.eventBus.on('MoveRight', () => this.handlePlayerMove(), {
			signal: this.abortController.signal
		});
		ctx.eventBus.on('MoveLeft', () => this.handlePlayerMove(), {
			signal: this.abortController.signal
		});
		ctx.eventBus.on(
			'GameOver',
			() => {
				this.args.gameOver = true;
			},
			{
				signal: this.abortController.signal
			}
		);
	}

	update(delta: number): void {
		if (this.ctx.store.get('GameOver')) return;
		if (this.args.timeLeft - delta * 1000 < 0) {
			this.args.timeLeft = 0;
			this.ctx.eventBus.emit('GameOver');
			this.ctx.store.set('GameOver', true);
		} else {
			this.args.timeLeft -= delta * 1000;
		}
	}

	handlePlayerMove() {
		if (this.ctx.store.get('GameOver')) return;
		if (this.args.timeLeft === 0) return;
		this.args.timeLeft = Math.min(this.initialTime, this.args.timeLeft + 200);
	}
}
