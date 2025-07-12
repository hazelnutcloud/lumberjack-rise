import { authClient } from '$lib/auth';
import { subjects } from 'auth-server/subjects';

export async function handle({ event, resolve }) {
	const accessToken = event.cookies.get('access_token');
	const refreshToken = event.cookies.get('refresh_token');

	if (!accessToken) {
		event.locals.user = null;
	} else {
		const verifyResult = await authClient.verify(subjects, accessToken, {
			refresh: refreshToken
		});

		if (verifyResult.err) {
			event.locals.user = null;
			event.cookies.delete('access_token', { path: '/' });
			event.cookies.delete('refresh_token', { path: '/' });
		} else {
			event.locals.user = verifyResult.subject.properties;

			if (verifyResult.tokens) {
				event.cookies.set('access_token', verifyResult.tokens.access, {
					path: '/'
				});
				event.cookies.set('refresh_token', verifyResult.tokens.refresh, {
					path: '/'
				});
			}
		}
	}

	return await resolve(event);
}
