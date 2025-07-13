import { createClient } from '@openauthjs/openauth/client';

export const getAuthclient = (env: Env) => {
	return createClient({
		clientID: 'auth-server',
		issuer: env.ISSUER_URL,
	});
};
