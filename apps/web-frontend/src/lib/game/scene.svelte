<script lang="ts">
	import { T } from '@threlte/core';
	import { Game } from './game.svelte';
	import { Text } from '@threlte/extras';
	import { GameObject } from './object.svelte';

	const game = new Game();
</script>

<svelte:window
	onkeydown={(evt) => game.handleKeydown(evt)}
	onkeyup={(evt) => game.handleKeyup(evt)}
/>

<T.PerspectiveCamera makeDefault position.z={7} fov={50} />

{#snippet renderObj(obj: GameObject)}
	{#if obj.texture}
		{#await obj.texture then texture}
			<T.Sprite position={obj.position} scale={obj.scale}>
				<T.SpriteMaterial map={texture}></T.SpriteMaterial>
			</T.Sprite>
		{/await}
	{/if}
	{#each obj.children as child, i (i)}
		{@render renderObj(child)}
	{/each}
{/snippet}

{#await game.init()}
	<Text text="Loading..."></Text>
{:then}
	{#each game.scene as obj, i (i)}
		{@render renderObj(obj)}
	{/each}
{/await}
