import { Hono } from 'hono';
import { createIssuer } from './issuer';

export function createApp(env: Env) {
	const app = new Hono();
	const issuer = createIssuer(env);

	app.route('/', issuer);

	return app;
}
