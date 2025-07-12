import { createClient } from '@openauthjs/openauth/client';

export const authClient = createClient({
	clientID: 'web-frontend',
	issuer: 'https://auth.lumberjack.localhost'
});
