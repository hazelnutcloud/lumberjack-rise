<script lang="ts">
	import Scene from '$lib/game/scene.svelte';
	import { Canvas } from '@threlte/core';

	const { data } = $props();
</script>

<div class="flex h-screen w-full items-stretch">
	<div class="max-w-xs p-4">
		{#if data.user}
			<div class="truncate text-sm">
				logged in as {data.user.address}
				{data.user.email ? `(${data.user.email})` : ''}
			</div>
			<form action="?/logout" method="POST">
				<button>Logout</button>
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
