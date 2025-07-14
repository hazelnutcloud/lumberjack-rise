<script lang="ts">
	import { T, useLoader, useTask } from '@threlte/core';
	import { Game } from './game.svelte';
	import { HTML, Text } from '@threlte/extras';
	import { GameObject, HTMLObject, SpriteObject } from './object.svelte';
	import { TextureLoader } from 'three';
	import { numberizeVector3 } from './utils/vector3';
	import { WebSocket } from 'partysocket';

	const { relayUrl }: { relayUrl: string | undefined } = $props();

	const loader = useLoader(TextureLoader);

	const game = new Game(loader);

	useTask((delta) => {
		game.update(delta);
	});

	$effect(() => {
		if (!relayUrl) {
			game.setWs(undefined);
			return;
		}

		const ws = new WebSocket(relayUrl);

		ws.onerror = (err) => {
			console.error(err.message);
		};

		game.setWs(ws);

		return () => {
			ws?.close();
		};
	});
</script>

<svelte:window
	onkeydown={(evt) => game.handleKeydown(evt)}
	onkeyup={(evt) => game.handleKeyup(evt)}
/>

<T.PerspectiveCamera makeDefault position.z={7} fov={50} />

{#snippet renderObj(obj: GameObject)}
	<T.Group position={numberizeVector3(obj.position)} scale={numberizeVector3(obj.scale)}>
		{#if obj instanceof SpriteObject}
			{#await obj.texture then texture}
				<T.Sprite>
					<T.SpriteMaterial map={texture}></T.SpriteMaterial>
				</T.Sprite>
			{/await}
		{:else if obj instanceof HTMLObject}
			{@const Component = obj.component}
			<HTML>
				<Component {...obj.args} />
			</HTML>
		{/if}
		{#each obj.children as child, i (i)}
			{@render renderObj(child)}
		{/each}
	</T.Group>
{/snippet}

{#await game.init()}
	<Text text="Loading..."></Text>
{:then}
	{#each game.scene as obj, i (i)}
		{@render renderObj(obj)}
	{/each}
{/await}
