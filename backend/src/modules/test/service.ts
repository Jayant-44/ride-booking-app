import { TestResponseSchema, type Test, type TestResponse } from './schemas.js';

import type { ServiceResponse } from '@/types/service.js';
import { addTwoNumbers } from '@/utils/index.js';
import { createServiceResponse } from '@/utils/service.js';

async function getTestData(data: Test): Promise<ServiceResponse<TestResponse>> {
	logger.info('Received test data', { data });
	const result = addTwoNumbers(1, 2);

	return createServiceResponse({
		data: { result: 1 },
		schema: TestResponseSchema,
		strict: true,
	});
}

export const TestService = {
	getTestData,
};
