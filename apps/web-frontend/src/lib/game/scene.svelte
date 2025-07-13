<script lang="ts">
	import { T, useLoader, useTask } from '@threlte/core';
	import { Game } from './game.svelte';
	import { HTML, Text } from '@threlte/extras';
	import { GameObject, HTMLObject, SpriteObject } from './object.svelte';
	import { TextureLoader } from 'three';

	const loader = useLoader(TextureLoader);

	const game = new Game(loader);

	useTask((delta) => {
		game.update(delta);
	});
</script>

<svelte:window
	onkeydown={(evt) => game.handleKeydown(evt)}
	onkeyup={(evt) => game.handleKeyup(evt)}
/>

<T.PerspectiveCamera makeDefault position.z={7} fov={50} />

{#snippet renderObj(obj: GameObject)}
	<T.Group position={obj.position} scale={obj.scale}>
		{#if obj instanceof SpriteObject}
			{#await obj.texture then texture}
				<T.Sprite>
					<T.SpriteMaterial map={texture}></T.SpriteMaterial>
				</T.Sprite>
			{/await}
		{:else if obj instanceof HTMLObject}
			<HTML>
				<svelte:component this={obj.component} {...obj.args}></svelte:component>
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
