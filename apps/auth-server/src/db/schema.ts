import { relations } from 'drizzle-orm';
import { index, integer, sqliteTable, text } from 'drizzle-orm/sqlite-core';

export const users = sqliteTable(
	'users',
	{
		id: integer().primaryKey({ autoIncrement: true }),
		email: text(),
		address: text().notNull(),
		pk: text().notNull(),
	},
	(table) => [index('address').on(table.address), index('email').on(table.email)],
);

export const oauthAccounts = sqliteTable(
	'oauth_accounts',
	{
		id: integer().primaryKey({ autoIncrement: true }),
		userId: integer().notNull(), // -> users.id
		providerId: text().notNull(), // Object.keys(providers) in issuer.ts,
		accountId: text().notNull(),
		accessToken: text(),
		refreshToken: text(),
		accessTokenExpiresAt: integer({ mode: 'timestamp_ms' }),
		refreshTokenExpiresAt: integer({ mode: 'timestamp_ms' }),
		createdAt: integer({ mode: 'timestamp_ms' }).$defaultFn(() => new Date()),
		updatedAt: integer({ mode: 'timestamp_ms' })
			.$defaultFn(() => new Date())
			.$onUpdateFn(() => new Date()),
	},
	(table) => [index('provider_account_idx').on(table.providerId, table.accountId)],
);

export const oauthAccountsRelations = relations(oauthAccounts, ({ one }) => ({
	user: one(users, {
		fields: [oauthAccounts.userId],
		references: [users.id],
	}),
}));
