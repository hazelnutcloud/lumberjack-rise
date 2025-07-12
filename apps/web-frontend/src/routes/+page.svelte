<script lang="ts">
	const { data } = $props();
</script>

{#if data.user}
	<div>
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
