import { Hono } from 'hono';
import { createIssuer } from './issuer';

export function createApp(env: Env) {
	const app = new Hono<{ Bindings: Env }>();

	const issuer = createIssuer(env);
	app.route('/', issuer);

	app.get('/relay', async (ctx) => {
		const upgradeHeader = ctx.req.header('Upgrade');

		if (!upgradeHeader || upgradeHeader !== 'websocket') {
			return ctx.text('Durable Object expected Upgrade: websocket', 426);
		}
	});

	return app;
}
