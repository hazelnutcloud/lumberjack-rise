<script lang="ts">
	import Scene from '$lib/game/scene.svelte';
	import { Canvas } from '@threlte/core';
	import { env } from '$env/dynamic/public';
	import { createPublicClient, http, zeroAddress, type Address } from 'viem';
	import { riseTestnet } from 'viem/chains';
	import { LUMBERJACK_CONTRACT } from '$lib/onchain/contracts/lumberjack.js';

	const { data } = $props();

	const url = new URL(env.PUBLIC_ISSUER_URL);
	const protocol = url.protocol === 'http:' ? 'ws:' : 'wss:';
	const relayUrl = $derived(
		data.accessToken && data.user?.address
			? `${protocol}//${url.host}/ws/relay/${data.user.address}?accessToken=${data.accessToken}`
			: undefined
	);
	const client = createPublicClient({
		chain: riseTestnet,
		transport: http()
	});
	let leaderboard = $state(getLeaderboard());

	function getLeaderboard() {
		return client.readContract({
			abi: LUMBERJACK_CONTRACT.abi,
			functionName: 'getLeaderboard',
			address: LUMBERJACK_CONTRACT[11155931].address
		});
	}

	function truncateAddress(address: string) {
		return address.slice(0, 6) + '...' + address.slice(address.length - 4);
	}

	function parseLeaderboard(
		leaderboardRaw: readonly [readonly `0x${string}`[], readonly bigint[]]
	) {
		return leaderboardRaw[0].reduce(
			(acc, curr, i) => {
				if (curr === zeroAddress) return acc;
				const score = leaderboardRaw[1][i];
				if (acc[curr]) {
					if (score > acc[curr]) {
						acc[curr] = score;
					}
				} else {
					acc[curr] = score;
				}
				return acc;
			},
			{} as Record<Address, bigint>
		);
	}
</script>

<div
	class="flex h-screen w-full items-stretch bg-[url('sprites/game-background.png')] bg-contain bg-center p-4"
>
	<div class="flex max-w-48 flex-col gap-1 rounded-xl bg-white/10 p-4 text-white backdrop-blur-md">
		{#if data.user}
			{@const address = data.user.address}
			<div class="text-sm">
				logged in as <span class="rounded bg-white/20 hover:cursor-pointer">
					<button
						onclick={() => {
							navigator.clipboard.writeText(address);
							window.alert('Address copied!');
						}}
					>
						{truncateAddress(address)}
					</button>
				</span>
			</div>
			{#if data.user.email}
				<div class="truncate text-sm">({data.user.email})</div>
			{/if}
			<form action="?/logout" method="POST">
				<button class="btn">Logout</button>
			</form>
		{:else}
			<form action="?/login" method="POST">
				<button>Login</button>
			</form>
		{/if}
		<div class="mt-4 flex flex-col items-start gap-1 text-sm">
			{#await leaderboard}
				Loading leaderboard...
			{:then leaderboardRaw}
				<div class="font-bold">Leaderboard</div>
				<button
					class="underline"
					onclick={() => {
						console.log('click');
						leaderboard = getLeaderboard();
					}}
				>
					refresh
				</button>
				{@const leaderboardParsed = parseLeaderboard(leaderboardRaw)}
				{#each Object.entries(leaderboardParsed) as [player, score], i (player)}
					<div class="flex w-full justify-between">
						<span>{i + 1}. {truncateAddress(player)}:</span>
						{score}
					</div>
				{/each}
			{/await}
		</div>
	</div>
	<div class="relative flex-1">
		<Canvas>
			<Scene {relayUrl} />
		</Canvas>
	</div>
</div>
