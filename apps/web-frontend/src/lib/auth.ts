import { env } from '$env/dynamic/public';
import { createClient } from '@openauthjs/openauth/client';

export const getAuthClient = () =>
	createClient({
		clientID: 'web-frontend',
		issuer: env.PUBLIC_ISSUER_URL
	});
