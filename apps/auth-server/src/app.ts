import { Hono } from 'hono';
import { createIssuer } from './issuer';
import { getAuthclient } from './utils/auth-client';
import { subjects } from './subjects';
import { routePartykitRequest } from 'partyserver';

export function createApp(env: Env) {
	const app = new Hono<{ Bindings: Env }>();

	const issuer = createIssuer(env);
	app.route('/', issuer);

	app.get('/ws/relay/:address', async (ctx) => {
		const upgradeHeader = ctx.req.header('Upgrade');
		if (!upgradeHeader || upgradeHeader !== 'websocket') {
			return ctx.text('Durable Object expected Upgrade: websocket', 426);
		}

		const accessToken = ctx.req.query('accessToken');
		if (!accessToken) return ctx.text('Unauthorized', 401);
		const authClient = getAuthclient(ctx.env);
		const verified = await authClient.verify(subjects, accessToken);

		if (verified.err) {
			return ctx.text('Unauthorized', 401);
		}

		const { properties } = verified.subject;

		const address = ctx.req.param('address');

		if (properties.address !== address) return ctx.text('Unauthorized', 401);

		return (await routePartykitRequest<Env>(ctx.req.raw, ctx.env as never, { prefix: 'ws' })) ?? ctx.notFound();
	});

	return app;
}
