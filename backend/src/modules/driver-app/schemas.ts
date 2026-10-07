import { z } from 'zod';

export const ProgressRideSchema = z.object({
  status: z.enum(['EN_ROUTE', 'ARRIVED', 'IN_PROGRESS', 'COMPLETED']),
  note: z.string().max(300).optional(),
});

export const RejectAssignmentSchema = z.object({
  reason: z.string().max(300).optional(),
});

export type ProgressRideInput = z.infer<typeof ProgressRideSchema>;
export type RejectAssignmentInput = z.infer<typeof RejectAssignmentSchema>;