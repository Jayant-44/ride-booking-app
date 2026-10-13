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

// -------------------- UPDATE PROFILE --------------------

export const UpdateProfileSchema = z
  .object({
    fullName: z.string().min(2).optional(),
    phone: z.string().min(8).optional(),
  })
  .refine((d) => Object.keys(d).length > 0, {
    message: 'At least one field is required',
  });

// -------------------- CHANGE PASSWORD --------------------

export const ChangePasswordSchema = z.object({
  currentPassword: z.string().min(1),
  newPassword: z.string().min(6, 'New password must be at least 6 characters'),
});

// -------------------- UPDATE SETTINGS --------------------

export const UpdateSettingsSchema = z
  .object({
    timezone: z.string().min(2).optional(),
    currency: z.string().length(3).optional(),
    locale: z.string().min(2).optional(),
  })
  .refine((d) => Object.keys(d).length > 0, {
    message: 'At least one setting is required',
  });

export type LoginInput = z.infer<typeof LoginSchema>;
export type RegisterInput = z.infer<typeof RegisterSchema>;
export type DriverRegisterInput = z.infer<typeof DriverRegisterSchema>;
export type AdminRegisterInput = z.infer<typeof AdminRegisterSchema>;
export type UpdateProfileInput = z.infer<typeof UpdateProfileSchema>;
export type ChangePasswordInput = z.infer<typeof ChangePasswordSchema>;
export type UpdateSettingsInput = z.infer<typeof UpdateSettingsSchema>;