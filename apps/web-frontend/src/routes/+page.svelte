<script lang="ts">
	import Scene from '$lib/game/scene.svelte';
	import { Canvas } from '@threlte/core';

	const { data } = $props();
</script>

<div
	class="flex h-screen w-full items-stretch bg-[url('sprites/game-background.png')] bg-contain bg-center p-4"
>
	<div class="max-w-48 rounded-xl bg-white/10 p-4 text-white backdrop-blur-md">
		{#if data.user}
			<div class="truncate text-sm">
				logged in as {data.user.address}
				{data.user.email ? `(${data.user.email})` : ''}
			</div>
			<form action="?/logout" method="POST">
				<button class="btn">Logout</button>
			</form>
		{:else}
			<form action="?/login" method="POST">
				<button>Login</button>
			</form>
		{/if}
	</div>
	<div class="flex-1">
		<Canvas>
			<Scene />
		</Canvas>
	</div>
</div>
