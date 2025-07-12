import { createSubjects } from '@openauthjs/openauth/subject';
import { type } from 'arktype';

export const subjects = createSubjects({
	user: type({
		address: 'string',
		email: 'string|null',
	}),
});
