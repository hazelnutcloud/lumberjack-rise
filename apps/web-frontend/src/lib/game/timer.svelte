<script lang="ts">
	const { timeLeft, gameOver }: { timeLeft: number; gameOver: boolean } = $props();

	const timeLeftRounded = $derived(Math.ceil(timeLeft / 1000));
</script>

<div class="flex w-32 flex-col items-center">
	{#if gameOver}
		<div class="text-lg font-bold text-red-700">GAME OVER</div>
	{:else}
		<progress max="5" value={timeLeftRounded} class="w-full"></progress>
		<div class="text-white">{timeLeftRounded} seconds left</div>
	{/if}
</div>
