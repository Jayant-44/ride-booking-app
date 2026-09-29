import type { Request, Response } from 'express';

import { ValidationError } from '@/config/errors/errors.js';
import { customParse } from '@/lib/zod.js';

import { AuthService } from './service.js';
import { RegisterSchema, LoginSchema } from './schemas.js';

export async function registerController(req: Request, res: Response): Promise<void> {
  const validation = customParse(RegisterSchema, req.body);
  if (!validation.success) throw new ValidationError(validation.message);

  try {
    const result = await AuthService.register(validation.data);
    res.success(result, 'Registration successful');
  } catch (err) {
    if (err instanceof Error && err.message === 'EMAIL_ALREADY_EXISTS') {
      res.status(409).json({ success: false, message: 'Email already registered' });
      return;
    }
    throw err;
  }
}

export async function loginController(req: Request, res: Response): Promise<void> {
  const validation = customParse(LoginSchema, req.body);
  if (!validation.success) throw new ValidationError(validation.message);

  try {
    const result = await AuthService.login(validation.data);
    res.success(result, 'Login successful');
  } catch (err) {
    if (err instanceof Error && err.message === 'INVALID_CREDENTIALS') {
      res.status(401).json({ success: false, message: 'Invalid email or password' });
      return;
    }
    throw err;
  }
}

export async function meController(req: Request, res: Response): Promise<void> {
  const userId = (req as any).user?.id;
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const user = await AuthService.me(userId);
  res.success(user);
}