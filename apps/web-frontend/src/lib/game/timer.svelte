<script lang="ts">
	const {
		timeLeft,
		gameState
	}: { timeLeft: number; gameState: 'waiting' | 'loading' | 'started' | 'over' } = $props();

	const timeLeftRounded = $derived(Math.ceil(timeLeft / 1000));
</script>

<div class="flex w-screen flex-col items-center">
	{#if gameState === 'waiting'}
		<div class="w-fit text-lg font-bold text-green-800">Press 'Enter' to start the game!</div>
	{:else if gameState === 'loading'}
		<div class="w-fit text-lg font-bold text-blue-800">Loading...</div>
	{:else if gameState === 'over'}
		<div class="text-lg font-bold text-red-700">GAME OVER</div>
	{:else}
		<progress max="5" value={timeLeftRounded} class="max-w-sm"></progress>
		<div class="text-white">{timeLeftRounded} seconds left</div>
	{/if}
</div>
