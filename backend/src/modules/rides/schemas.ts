import { z } from 'zod';

export const CreateRideSchema = z.object({
  pickupAddress: z.string().min(3, 'Pickup address is required'),
  pickupLat: z.number().min(-90).max(90).optional().default(0),
  pickupLng: z.number().min(-180).max(180).optional().default(0),
  dropoffAddress: z.string().min(3, 'Drop-off address is required'),
  dropoffLat: z.number().min(-90).max(90).optional().default(0),
  dropoffLng: z.number().min(-180).max(180).optional().default(0),
  scheduledAt: z.string().min(1, 'Date and time are required'),
  passengers: z.number().int().min(1).max(20),
  luggageCount: z.number().int().min(0).max(50),
  vehicleType: z.string().optional(),
  notes: z.string().max(500).optional(),
});

export const CancelRideSchema = z.object({
  reason: z.string().max(300).optional(),
});

export type CreateRideInput = z.infer<typeof CreateRideSchema>;
export type CancelRideInput = z.infer<typeof CancelRideSchema>;