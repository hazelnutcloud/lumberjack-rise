import { integer, sqliteTable, text } from 'drizzle-orm/sqlite-core';

export const users = sqliteTable('users', {
	id: integer().primaryKey({ autoIncrement: true }),
	address: text().notNull(),
	pk: text().notNull(),
});
