import { issuer } from '@openauthjs/openauth';
import { CloudflareStorage } from '@openauthjs/openauth/storage/cloudflare';
import { subjects } from './subjects';
import { DiscordProvider } from '@openauthjs/openauth/provider/discord';
import { drizzle } from 'drizzle-orm/d1';
import { schema } from './db';
import { generatePrivateKey, privateKeyToAddress } from 'viem/accounts';

export const createIssuer = (env: Env) =>
	issuer({
		storage: CloudflareStorage({
			namespace: env.AUTH as never,
		}),
		subjects,
		providers: {
			discord: DiscordProvider({
				clientID: env.DISCORD_CLIENT_ID,
				clientSecret: env.DISCORD_CLIENT_SECRET,
				scopes: [],
			}),
		},
		success: async (ctx, value) => {
			const pk = generatePrivateKey();
			const address = privateKeyToAddress(pk);

			const db = drizzle(env.DB, { schema });
			await db.insert(schema.users).values({
				address,
				pk,
			});

			return ctx.subject('user', {
				address,
			});
		},
	});
