import { defineConfig } from 'drizzle-kit';
import { type } from 'arktype';

const env = type({
	CLOUDFLARE_ACCOUNT_ID: 'string',
	CLOUDFLARE_DATABASE_ID: 'string',
	CLOUDFLARE_D1_TOKEN: 'string',
})(process.env);

if (env instanceof type.errors) {
	console.error(env);
	process.exit(1);
}

export default defineConfig({
	dialect: 'sqlite',
	driver: 'd1-http',
	out: './migrations',
	schema: './src/db/schema.ts',
	dbCredentials: {
		accountId: env.CLOUDFLARE_ACCOUNT_ID,
		databaseId: env.CLOUDFLARE_DATABASE_ID,
		token: env.CLOUDFLARE_D1_TOKEN,
	},
});
