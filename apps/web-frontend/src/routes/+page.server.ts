import { authClient } from '$lib/auth';
import { redirect } from '@sveltejs/kit';
import type { Actions } from './$types';

export const actions = {
	async login(event) {
		if (event.locals.user) {
			return event.locals.user;
		}

		const { url } = await authClient.authorize(`${event.url.origin}/api/callback`, 'code');

		redirect(303, url);
	},
	async logout(event) {
		event.cookies.delete('access_token', { path: '/' });
		event.cookies.delete('refresh_token', { path: '/' });
		event.locals.user = null;
	}
} satisfies Actions;
