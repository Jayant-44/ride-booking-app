import { z } from 'zod';

export const ListRidesQuerySchema = z.object({
  status: z.string().optional(),
  from: z.string().optional(),
  to: z.string().optional(),
});

export const RejectRideSchema = z.object({
  reason: z.string().max(300).optional(),
});

export type ListRidesQuery = z.infer<typeof ListRidesQuerySchema>;
export type RejectRideInput = z.infer<typeof RejectRideSchema>;