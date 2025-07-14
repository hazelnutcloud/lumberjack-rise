import { type } from 'arktype';
import { drizzle } from 'drizzle-orm/d1';
import { Connection, ConnectionContext, Server, WSMessage } from 'partyserver';
import { createWalletClient, fallback, Hex, hexToBigInt, http, TransactionReceipt, webSocket } from 'viem';
import { schema } from './db';
import { eq } from 'drizzle-orm';
import { riseTestnet } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';
import PQueue from 'p-queue';
import { shredActions } from 'shreds/viem';
import pRetry from 'p-retry';
import { Json } from 'ox';

export const RelaySchema = type.module({
	TxRequest: {
		id: 'number',
		type: "'sendTransaction'",
		to: 'string',
		value: 'string',
		input: 'string',
	},
	ClientSchema: 'TxRequest',
});

export type ServerSchema =
	| {
			type: 'error';
			message: string;
			id?: number;
	  }
	| {
			type: 'txSuccess';
			receipt: TransactionReceipt;
			id: number;
	  };

const createClient = (pk: Hex) =>
	createWalletClient({
		chain: riseTestnet,
		transport: fallback([http(), webSocket()]),
		account: privateKeyToAccount(pk),
	}).extend(shredActions);

export class Relay extends Server<Env> {
	client!: ReturnType<typeof createClient>;
	requestQueue!: PQueue;

	async onStart() {
		const db = drizzle(this.env.DB, { schema });

		const user = await db.query.users.findFirst({
			where: eq(schema.users.address, this.name),
		});

		if (!user) {
			console.error(`User with address ${this.name} not found in DB`);
			throw new Error('User not found');
		}

		this.client = createClient(user.pk as Hex);
		this.requestQueue = new PQueue({ concurrency: 1 });
	}

	onConnect(connection: Connection, ctx: ConnectionContext): void | Promise<void> {
		console.log('Connected', connection.id, 'to server', this.name);
	}

	async onMessage(connection: Connection, message: WSMessage) {
		const msg = (() => {
			if (typeof message === 'string') return message;

			return new TextDecoder().decode(message);
		})();

		console.log(msg);
		const body = RelaySchema.ClientSchema(JSON.parse(msg));

		if (body instanceof type.errors) {
			connection.send(
				JSON.stringify({
					type: 'error',
					message: body.summary,
				} satisfies ServerSchema),
			);
			return;
		}

		const handleWithRetry = () => pRetry(() => this.handleTxRequest(body), { retries: 2 });

		try {
			const res = await this.requestQueue.add(handleWithRetry);

			if (!res) throw new Error('unexpected empty response');

			connection.send(Json.stringify({ type: 'txSuccess', receipt: res, id: body.id } satisfies ServerSchema));
		} catch (err) {
			console.error('revert data: ', (err as any).data);
			if (err instanceof Error) {
				connection.send(JSON.stringify({ type: 'error', message: err.message } satisfies ServerSchema));
			} else {
				connection.send(JSON.stringify({ type: 'error', message: `${err}` } satisfies ServerSchema));
			}
		}
	}

	async handleTxRequest(txRequest: typeof RelaySchema.TxRequest.infer) {
		const request = await this.client.prepareTransactionRequest({
			chain: riseTestnet,
			to: txRequest.to as Hex,
			data: txRequest.input as Hex,
			value: hexToBigInt(txRequest.value as Hex),
		});

		const serializedTransaction = await this.client.signTransaction(request);

		const txReceipt = await this.client.sendRawTransactionSync({
			serializedTransaction,
		});

		return txReceipt;
	}
}
