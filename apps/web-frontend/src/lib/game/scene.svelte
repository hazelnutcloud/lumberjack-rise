<script lang="ts">
	import { T, useLoader } from '@threlte/core';
	import { Game } from './game.svelte';
	import { Text } from '@threlte/extras';
	import { GameObject } from './object.svelte';
	import { TextureLoader } from 'three';

	const loader = useLoader(TextureLoader);

	const game = new Game(loader);
</script>

<svelte:window
	onkeydown={(evt) => game.handleKeydown(evt)}
	onkeyup={(evt) => game.handleKeyup(evt)}
/>

<T.PerspectiveCamera makeDefault position.z={7} fov={50} />

{#snippet renderObj(obj: GameObject)}
	<T.Group position={obj.position} scale={obj.scale}>
		{#if obj.texture}
			{#await obj.texture then texture}
				<T.Sprite>
					<T.SpriteMaterial map={texture}></T.SpriteMaterial>
				</T.Sprite>
			{/await}
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
