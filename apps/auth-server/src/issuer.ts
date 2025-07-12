import { issuer } from '@openauthjs/openauth';
import { CloudflareStorage } from '@openauthjs/openauth/storage/cloudflare';
import { subjects } from './subjects';
import { DiscordProvider } from '@openauthjs/openauth/provider/discord';
import { drizzle } from 'drizzle-orm/d1';
import { schema } from './db';
import { generatePrivateKey, privateKeyToAddress } from 'viem/accounts';
import { Select } from '@openauthjs/openauth/ui/select';
import { RESTGetAPIUserResult } from 'discord.js';
import { and, eq } from 'drizzle-orm';

export function createIssuer(env: Env) {
	return issuer({
		select: Select({
			providers: {
				discord: {
					display: 'Discord',
				},
			},
		}),
		storage: CloudflareStorage({
			namespace: env.AUTH as never,
		}),
		subjects,
		providers: {
			discord: DiscordProvider({
				clientID: env.DISCORD_CLIENT_ID,
				clientSecret: env.DISCORD_CLIENT_SECRET,
				scopes: ['identify', 'email'],
			}),
		},
		success: async (ctx, value, req) => {
			switch (value.provider) {
				case 'discord': {
					const { REST, Routes, RequestMethod } = await import('discord.js');

					const client = new REST({ authPrefix: 'Bearer' }).setToken(value.tokenset.access);

					const discordUser = (await client.request({
						fullRoute: Routes.user(),
						method: RequestMethod.Get,
					})) as RESTGetAPIUserResult;

					const db = drizzle(env.DB, { schema });

					let registeredUser: typeof schema.users.$inferSelect | undefined;

					if (discordUser.email) {
						registeredUser = await db.query.users.findFirst({
							where: eq(schema.users.email, discordUser.email),
						});
					}

					if (!registeredUser) {
						const registeredOauthAccount = await db.query.oauthAccounts.findFirst({
							where: and(eq(schema.oauthAccounts.providerId, 'discord'), eq(schema.oauthAccounts.accountId, discordUser.id)),
							with: {
								user: true,
							},
						});
						if (registeredOauthAccount) {
							registeredUser = registeredOauthAccount.user;
						}
					}

					if (registeredUser) {
						return ctx.subject('user', {
							address: registeredUser.address,
							email: registeredUser.email,
						});
					}

					// TODO: implement linking
					const pk = generatePrivateKey();
					const address = privateKeyToAddress(pk);

					const [newUser] = await db
						.insert(schema.users)
						.values({
							address,
							pk,
							email: discordUser.email,
						})
						.returning();

					const expiry = new Date(Date.now() + value.tokenset.expiry * 1000);
					await db.insert(schema.oauthAccounts).values({
						accountId: discordUser.id,
						providerId: 'discord',
						userId: newUser.id,
						accessToken: value.tokenset.access,
						accessTokenExpiresAt: expiry,
						refreshToken: value.tokenset.refresh,
						refreshTokenExpiresAt: expiry,
					});

					return ctx.subject('user', {
						address,
						email: discordUser.email ?? null,
					});
				}
			}
		},
	});
}
