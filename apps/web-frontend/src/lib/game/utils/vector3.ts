import type { Vector3 } from '../types';

export function numberizeVector3(vector: Vector3) {
	return vector.map((num) => {
		if (typeof num === 'number') {
			return num;
		}
		return num.current;
	}) as [number, number, number];
}
