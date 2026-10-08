import { z } from 'zod';

export const ListRidesQuerySchema = z.object({
  status: z.string().optional(),
  from: z.string().optional(),
  to: z.string().optional(),
});

export const RejectRideSchema = z.object({
  reason: z.string().max(300).optional(),
});

export const RejectUserSchema = z.object({
  reason: z.string().max(300).optional(),
});

export const ListPendingQuerySchema = z.object({
  role: z.enum(['DRIVER', 'ADMIN']).optional(),
});

export type ListRidesQuery = z.infer<typeof ListRidesQuerySchema>;
export type RejectRideInput = z.infer<typeof RejectRideSchema>;
export type RejectUserInput = z.infer<typeof RejectUserSchema>;
export type ListPendingQuery = z.infer<typeof ListPendingQuerySchema>;