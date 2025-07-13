import type Emittery from 'emittery';
import type { inputMap } from './game.svelte';
import type { GameObject } from './object.svelte';
import type { TextureLoader } from 'three';
import type { useLoader } from '@threlte/core';
import type { Spring, Tween } from 'svelte/motion';

// https://developer.mozilla.org/en-US/docs/Web/API/UI_Events/Keyboard_event_key_values -> command
export type InputMap = Record<`${'keydown' | 'keyup'}:${string}`, string>;
export type EventBus = Emittery<
	{
		[command in Commands]: KeyboardEvent;
	} & {
		[key: string]: any;
	}
>;
export type Commands = (typeof inputMap)[keyof typeof inputMap];
export type GameContext = {
	eventBus: EventBus;
	remove: (obj: GameObject) => void;
	textureLoader: ReturnType<typeof useLoader<typeof TextureLoader>>;
	store: Map<string, any>;
};
export type NumberOrTweenOrSpring = number | Tween<number> | Spring<number>;
export type Vector3 = [NumberOrTweenOrSpring, NumberOrTweenOrSpring, NumberOrTweenOrSpring];
