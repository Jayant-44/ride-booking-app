import { z } from 'zod';

// -------------------- LOGIN --------------------

export const LoginSchema = z
  .object({
    identifier: z.string().min(3).optional(),
    email: z.string().email().optional(),
    phone: z.string().optional(),
    password: z.string().min(1),
    uniqueId: z.string().optional(),
  })
  .refine(
    (data) => Boolean(data.identifier || data.email || data.phone),
    { message: 'Email, phone, or identifier is required' }
  );

// -------------------- CUSTOMER REGISTER --------------------

export const RegisterSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  fullName: z.string().min(2, 'Full name is required'),
  phone: z.string().min(8, 'Phone number is required'),
  timezone: z.string().default('UTC'),
  currency: z.string().length(3).default('USD'),
  locale: z.string().default('en'),
  // NOTE: role is intentionally not accepted — always CUSTOMER
});

// -------------------- DRIVER REGISTER --------------------

export const DriverRegisterSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  fullName: z.string().min(2),
  phone: z.string().min(8),
  licenseNo: z.string().min(3),
  licenseExpiry: z.string(),
  timezone: z.string().default('Asia/Kolkata'),
  currency: z.string().length(3).default('INR'),
  locale: z.string().default('en'),
  vehicle: z.object({
    make: z.string().min(2),
    model: z.string().min(1),
    plateNo: z.string().min(3),
    color: z.string().min(2),
    capacity: z.number().int().min(1).max(20),
    luggageCapacity: z.number().int().min(0).max(30),
  }),
});

// -------------------- ADMIN REGISTER --------------------

export const AdminRegisterSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  fullName: z.string().min(2),
  phone: z.string().min(8),
  timezone: z.string().default('Asia/Kolkata'),
  currency: z.string().length(3).default('INR'),
  locale: z.string().default('en'),
});

export type LoginInput = z.infer<typeof LoginSchema>;
export type RegisterInput = z.infer<typeof RegisterSchema>;
export type DriverRegisterInput = z.infer<typeof DriverRegisterSchema>;
export type AdminRegisterInput = z.infer<typeof AdminRegisterSchema>;