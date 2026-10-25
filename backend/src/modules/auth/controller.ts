import type { Request, Response } from 'express';

import { ValidationError } from '@/config/errors/errors.js';
import { customParse } from '@/lib/zod.js';

import { AuthService } from './service.js';
import {
  RegisterSchema,
  LoginSchema,
  DriverRegisterSchema,
  AdminRegisterSchema,
  UpdateProfileSchema,
  ChangePasswordSchema,
  UpdateSettingsSchema,
} from './schemas.js';

export async function registerController(req: Request, res: Response): Promise<void> {
  const v = customParse(RegisterSchema, req.body);
  if (!v.success) throw new ValidationError(v.message);

  try {
    const result = await AuthService.register(v.data);
    res.success(result, 'Registration successful');
  } catch (err) {
    if (err instanceof Error && err.message === 'EMAIL_OR_PHONE_TAKEN') {
      res.status(409).json({ success: false, message: 'Email or phone already registered' });
      return;
    }
    throw err;
  }
}

export async function forgotPasswordController(req: Request, res: Response) {
  const { email } = req.body;
  if (!email) { res.status(400).json({ success: false, message: 'Email required' }); return; }
  try {
    const result = await AuthService.forgotPassword(email);
    res.success(result, result.message);
  } catch (err: any) {
    if (err.message === 'EMAIL_NOT_FOUND') { res.status(404).json({ success: false, message: 'Email not found' }); return; }
    throw err;
  }
}

export async function resetPasswordController(req: Request, res: Response) {
  const { email, code, newPassword } = req.body;
  if (!email || !code || !newPassword) { res.status(400).json({ success: false, message: 'All fields required' }); return; }
  try {
    const result = await AuthService.resetPassword(email, code, newPassword);
    res.success(result, result.message);
  } catch (err: any) {
    if (err.message === 'INVALID_CODE') { res.status(400).json({ success: false, message: 'Invalid code' }); return; }
    if (err.message === 'CODE_EXPIRED') { res.status(400).json({ success: false, message: 'Code expired' }); return; }
    throw err;
  }
}

export async function registerDriverController(req: Request, res: Response): Promise<void> {
  const v = customParse(DriverRegisterSchema, req.body);
  if (!v.success) throw new ValidationError(v.message);

  try {
    const result = await AuthService.registerDriver(v.data);
    res.success(result, result.message);
  } catch (err) {
    if (err instanceof Error && err.message === 'EMAIL_OR_PHONE_TAKEN') {
      res.status(409).json({ success: false, message: 'Email or phone already registered' });
      return;
    }
    if (err instanceof Error && err.message === 'PLATE_TAKEN') {
      res.status(409).json({ success: false, message: 'Vehicle plate already registered' });
      return;
    }
    throw err;
  }
}

export async function registerAdminController(req: Request, res: Response): Promise<void> {
  const v = customParse(AdminRegisterSchema, req.body);
  if (!v.success) throw new ValidationError(v.message);

  try {
    const result = await AuthService.registerAdmin(v.data);
    res.success(result, result.message);
  } catch (err) {
    if (err instanceof Error && err.message === 'EMAIL_OR_PHONE_TAKEN') {
      res.status(409).json({ success: false, message: 'Email or phone already registered' });
      return;
    }
    throw err;
  }
}

export async function loginController(req: Request, res: Response): Promise<void> {
  const v = customParse(LoginSchema, req.body);
  if (!v.success) throw new ValidationError(v.message);

  try {
    const result = await AuthService.login(v.data);
    res.success(result, 'Login successful');
  } catch (err) {
    if (err instanceof Error) {
      switch (err.message) {
        case 'INVALID_CREDENTIALS':
          res.status(401).json({ success: false, message: 'Invalid credentials' });
          return;
        case 'ACCOUNT_PENDING':
          res.status(403).json({
            success: false,
            message: 'Your account is awaiting approval. Contact the admin.',
          });
          return;
        case 'ACCOUNT_SUSPENDED':
          res.status(403).json({ success: false, message: 'Account suspended' });
          return;
        case 'UNIQUE_ID_REQUIRED':
          res.status(400).json({
            success: false,
            message: 'This account requires a Driver/Admin ID',
          });
          return;
        case 'INVALID_UNIQUE_ID':
          res.status(401).json({ success: false, message: 'Invalid Driver/Admin ID' });
          return;
      }
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

export async function updateProfileController(
  req: Request,
  res: Response
): Promise<void> {
  const userId = (req as any).user?.id;
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const v = customParse(UpdateProfileSchema, req.body);
  if (!v.success) throw new ValidationError(v.message);

  try {
    const user = await AuthService.updateProfile(userId, v.data);
    res.success(user, 'Profile updated');
  } catch (err) {
    if (err instanceof Error && err.message === 'PHONE_TAKEN') {
      res.status(409).json({
        success: false,
        message: 'Phone number already in use',
      });
      return;
    }
    throw err;
  }
}

export async function changePasswordController(
  req: Request,
  res: Response
): Promise<void> {
  const userId = (req as any).user?.id;
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const v = customParse(ChangePasswordSchema, req.body);
  if (!v.success) throw new ValidationError(v.message);

  try {
    const result = await AuthService.changePassword(userId, v.data);
    res.success(result, result.message);
  } catch (err) {
    if (err instanceof Error && err.message === 'INVALID_CURRENT_PASSWORD') {
      res.status(400).json({
        success: false,
        message: 'Current password is incorrect',
      });
      return;
    }
    throw err;
  }
}

export async function updateSettingsController(
  req: Request,
  res: Response
): Promise<void> {
  const userId = (req as any).user?.id;
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const v = customParse(UpdateSettingsSchema, req.body);
  if (!v.success) throw new ValidationError(v.message);

  const user = await AuthService.updateSettings(userId, v.data);
  res.success(user, 'Settings updated');
}

export async function googleLoginController(req: Request, res: Response): Promise<void> {
  const { idToken } = req.body;
  
  if (!idToken) {
    res.status(400).json({ success: false, message: 'ID Token is required' });
    return;
  }

  try {
    const result = await AuthService.googleLogin(idToken);
    res.success(result, 'Google login successful');
  } catch (err) {
    if (err instanceof Error && err.message === 'INVALID_GOOGLE_TOKEN') {
      res.status(401).json({ success: false, message: 'Invalid Google token' });
      return;
    }
    throw err;
  }
}