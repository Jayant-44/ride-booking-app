import { z } from 'zod';

export const CreateDriverSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6).default('driver123'),
  fullName: z.string().min(2),
  phone: z.string().min(8),
  licenseNo: z.string().min(3),
  licenseExpiry: z.string(), // ISO date string
  timezone: z.string().default('Asia/Kolkata'),
  currency: z.string().length(3).default('INR'),
  locale: z.string().default('en'),

  // Vehicle (required for new drivers)
  vehicle: z.object({
    make: z.string().min(2),
    model: z.string().min(1),
    plateNo: z.string().min(3),
    color: z.string().min(2),
    capacity: z.number().int().min(1).max(20),
    luggageCapacity: z.number().int().min(0).max(30),
  }),
});

export const AssignDriverSchema = z.object({
  driverId: z.string().min(1),
  vehicleId: z.string().min(1),
});

export type CreateDriverInput = z.infer<typeof CreateDriverSchema>;
export type AssignDriverInput = z.infer<typeof AssignDriverSchema>;