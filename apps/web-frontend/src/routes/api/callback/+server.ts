import { getAuthClient } from '$lib/auth';
import { error, redirect } from '@sveltejs/kit';

export async function GET({ url, cookies }) {
	const code = url.searchParams.get('code');

	if (!code) {
		error(400);
	}

	const authClient = getAuthClient();

	const exchanged = await authClient.exchange(code, `${url.origin}/api/callback`);

	if (exchanged.err) {
		error(400, exchanged.err);
	}

	cookies.set('access_token', exchanged.tokens.access, { path: '/' });
	cookies.set('refresh_token', exchanged.tokens.refresh, { path: '/' });

	redirect(302, url.origin);
}
