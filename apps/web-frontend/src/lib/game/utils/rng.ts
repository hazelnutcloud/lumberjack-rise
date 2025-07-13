export function randomBigInt256(): bigint {
	// Generate 32 random bytes (256 bits)
	const bytes = new Uint8Array(32);

	// Fill with random values
	crypto.getRandomValues(bytes);

	// Convert bytes to hex string
	const hex = Array.from(bytes)
		.map((b) => b.toString(16).padStart(2, '0'))
		.join('');

	// Convert hex string to BigInt
	return BigInt('0x' + hex);
}
