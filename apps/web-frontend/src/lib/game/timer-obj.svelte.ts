import type { ComponentProps } from 'svelte';
import { HTMLObject } from './object.svelte';
import TimerComponent from './timer.svelte';
import type { GameContext } from './types';

export class Timer extends HTMLObject {
	position: [number, number, number] = [-5.4, -2.4, 1];
	component = TimerComponent;
	args: ComponentProps<typeof TimerComponent>;
	abortController = new AbortController();
	initialTime: number;

	constructor(ctx: GameContext, timeLeft: number) {
		super(ctx);
		this.args = $state({ timeLeft, gameState: 'waiting' });
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
				ctx.store.set('GameState', 'GAME_OVER');
				this.args.gameState = 'over';
			},
			{
				signal: this.abortController.signal
			}
		);
		ctx.eventBus.on(
			'StartGame',
			() => {
				ctx.store.set('GameState', 'GAME_STARTED');
				this.args.gameState = 'started';
			},
			{
				signal: this.abortController.signal
			}
		);
		ctx.eventBus.on(
			'GameLoading',
			() => {
				this.args.gameState = 'loading';
			},
			{
				signal: this.abortController.signal
			}
		);
	}

	update(delta: number): void {
		const gameState = this.ctx.store.get('GameState');
		if (!gameState || gameState === 'GAME_OVER') return;
		if (this.args.timeLeft - delta * 1000 < 0) {
			this.args.timeLeft = 0;
		} else {
			this.args.timeLeft -= delta * 1000;
		}
	}

	handlePlayerMove() {
		const gameState = this.ctx.store.get('GameState');
		if (!gameState || gameState === 'GAME_OVER') return;
		this.args.timeLeft = Math.min(this.initialTime, this.args.timeLeft + 200);
	}
}
