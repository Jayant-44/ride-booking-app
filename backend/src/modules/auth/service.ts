import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

import { prisma } from '@/lib/clients/prisma.js';
import { getAuth } from 'firebase-admin/auth';

import type {
  LoginInput,
  RegisterInput,
  DriverRegisterInput,
  AdminRegisterInput,
  UpdateProfileInput,
  ChangePasswordInput,
  UpdateSettingsInput,
} from './schemas.js';

const SALT_ROUNDS = 10;
const JWT_SECRET = process.env.JWT_SECRET ?? 'dev-secret-change-me';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN ?? '7d';
const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

const userSelect = {
  id: true,
  email: true,
  fullName: true,
  phone: true,
  role: true,
  status: true,
  uniqueId: true,
  isSuperAdmin: true,
  timezone: true,
  currency: true,
  locale: true,
  createdAt: true,
  gender: true,
  dateOfBirth: true,
  emergencyContact: true,
} as const;

function signToken(
  userId: string,
  role: string,
  isSuperAdmin: boolean
): string {
  return jwt.sign(
    { sub: userId, role, isSuperAdmin },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN } as jwt.SignOptions
  );
}

export async function generateUniqueId(prefix: 'DRV' | 'ADM'): Promise<string> {
  for (let attempt = 0; attempt < 10; attempt++) {
    let id = `${prefix}-`;
    for (let i = 0; i < 8; i++) {
      id += ALPHABET[Math.floor(Math.random() * ALPHABET.length)];
    }
    const existing = await prisma.user.findUnique({ where: { uniqueId: id } });
    if (!existing) return id;
  }
  throw new Error('UNIQUE_ID_GENERATION_FAILED');
}

export const AuthService = {
  // ---------- LOGIN ----------
  async login(input: LoginInput) {
    const identifier = input.identifier ?? input.email ?? input.phone!;

    const user = await prisma.user.findFirst({
      where: {
        OR: [{ email: identifier }, { phone: identifier }],
      },
    });

    if (!user) throw new Error('INVALID_CREDENTIALS');

    const passwordMatches = await bcrypt.compare(input.password, user.password);
    if (!passwordMatches) throw new Error('INVALID_CREDENTIALS');

    if (user.status === 'PENDING') throw new Error('ACCOUNT_PENDING');
    if (user.status === 'SUSPENDED') throw new Error('ACCOUNT_SUSPENDED');

    // Drivers and admins must supply a matching uniqueId
    if (user.uniqueId) {
      if (!input.uniqueId) throw new Error('UNIQUE_ID_REQUIRED');
      if (input.uniqueId.toUpperCase() !== user.uniqueId.toUpperCase()) {
        throw new Error('INVALID_UNIQUE_ID');
      }
    }

    const token = signToken(user.id, user.role, user.isSuperAdmin);
    const { password: _omit, ...safeUser } = user;
    return { user: safeUser, token };
  },

  async forgotPassword(email: string) {
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) throw new Error('EMAIL_NOT_FOUND');

    // Generate 6-digit code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 mins

    await prisma.user.update({
      where: { id: user.id },
      data: { resetCode: code, resetCodeExpiresAt: expiresAt },
    });

    const { sendResetEmail } = await import('../../lib/mailer.js');
    await sendResetEmail(user.email, code);

    return { message: 'Reset code sent to email' };
  },

  async resetPassword(email: string, code: string, newPassword: string) {
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) throw new Error('EMAIL_NOT_FOUND');

    if (user.resetCode !== code) throw new Error('INVALID_CODE');
    if (user.resetCodeExpiresAt && user.resetCodeExpiresAt < new Date()) {
      throw new Error('CODE_EXPIRED');
    }

    const hashedPassword = await bcrypt.hash(newPassword, SALT_ROUNDS);

    await prisma.user.update({
      where: { id: user.id },
      data: {
        password: hashedPassword,
        resetCode: null,
        resetCodeExpiresAt: null,
      },
    });

    return { message: 'Password reset successful' };
  },

  // ---------- CUSTOMER REGISTER ----------
  async register(input: RegisterInput) {
    const existing = await prisma.user.findFirst({
      where: { OR: [{ email: input.email }, { phone: input.phone }] },
    });
    if (existing) throw new Error('EMAIL_OR_PHONE_TAKEN');

    const hashedPassword = await bcrypt.hash(input.password, SALT_ROUNDS);

    const user = await prisma.user.create({
      data: {
        email: input.email,
        password: hashedPassword,
        fullName: input.fullName,
        phone: input.phone,
        role: 'CUSTOMER',
        status: 'ACTIVE',
        timezone: input.timezone,
        currency: input.currency,
        locale: input.locale,
      },
      select: userSelect,
    });

    await prisma.customer.create({ data: { userId: user.id } });

    const token = signToken(user.id, user.role, false);
    return { user, token };
  },

  // ---------- DRIVER REGISTER (pending approval) ----------
  async registerDriver(input: DriverRegisterInput) {
    const existing = await prisma.user.findFirst({
      where: { OR: [{ email: input.email }, { phone: input.phone }] },
    });
    if (existing) throw new Error('EMAIL_OR_PHONE_TAKEN');

    const plateExists = await prisma.vehicle.findUnique({
      where: { plateNo: input.vehicle.plateNo },
    });
    if (plateExists) throw new Error('PLATE_TAKEN');

    const hashedPassword = await bcrypt.hash(input.password, SALT_ROUNDS);

    await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          email: input.email,
          password: hashedPassword,
          fullName: input.fullName,
          phone: input.phone,
          role: 'DRIVER',
          status: 'PENDING',
          timezone: input.timezone,
          currency: input.currency,
          locale: input.locale,
        },
      });

      const driver = await tx.driver.create({
        data: {
          userId: user.id,
          licenseNo: input.licenseNo,
          licenseExpiry: new Date(input.licenseExpiry),
          status: 'PENDING',
          isAvailable: false,
        },
      });

      await tx.vehicle.create({
        data: {
          driverId: driver.id,
          make: input.vehicle.make,
          model: input.vehicle.model,
          plateNo: input.vehicle.plateNo,
          color: input.vehicle.color,
          capacity: input.vehicle.capacity,
          luggageCapacity: input.vehicle.luggageCapacity,
          active: false,
        },
      });
    });

    return { message: 'Registration received. Awaiting admin approval.' };
  },

  // ---------- ADMIN REGISTER (pending super-admin approval) ----------
  async registerAdmin(input: AdminRegisterInput) {
    const existing = await prisma.user.findFirst({
      where: { OR: [{ email: input.email }, { phone: input.phone }] },
    });
    if (existing) throw new Error('EMAIL_OR_PHONE_TAKEN');

    const hashedPassword = await bcrypt.hash(input.password, SALT_ROUNDS);

    await prisma.user.create({
      data: {
        email: input.email,
        password: hashedPassword,
        fullName: input.fullName,
        phone: input.phone,
        role: 'ADMIN',
        status: 'PENDING',
        timezone: input.timezone,
        currency: input.currency,
        locale: input.locale,
      },
    });

    return { message: 'Registration received. Awaiting super admin approval.' };
  },

  // ---------- ME ----------
  async me(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: userSelect,
    });
    if (!user) throw new Error('USER_NOT_FOUND');
    return user;
  },
    // ---------- UPDATE PROFILE (name / phone) ----------
   async updateProfile(userId: string, input: UpdateProfileInput) {
    if (input.phone) {
      const conflict = await prisma.user.findFirst({
        where: { phone: input.phone, NOT: { id: userId } },
      });
      if (conflict) throw new Error('PHONE_TAKEN');
    }

    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        ...(input.fullName !== undefined && { fullName: input.fullName }),
        ...(input.phone !== undefined && { phone: input.phone }),
        ...(input.gender !== undefined && { gender: input.gender }),
        ...(input.dateOfBirth !== undefined && { dateOfBirth: new Date(input.dateOfBirth) }),
        ...(input.emergencyContact !== undefined && { emergencyContact: input.emergencyContact }),
      },
      select: userSelect,
    });

    return user;
  },

  // ---------- CHANGE PASSWORD ----------
  async changePassword(userId: string, input: ChangePasswordInput) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new Error('USER_NOT_FOUND');

    const matches = await bcrypt.compare(input.currentPassword, user.password);
    if (!matches) throw new Error('INVALID_CURRENT_PASSWORD');

    const hashed = await bcrypt.hash(input.newPassword, SALT_ROUNDS);
    await prisma.user.update({
      where: { id: userId },
      data: { password: hashed },
    });

    return { message: 'Password updated successfully' };
  },

  // ---------- UPDATE SETTINGS (timezone / currency / locale) ----------
  async updateSettings(userId: string, input: UpdateSettingsInput) {
    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        ...(input.timezone !== undefined && { timezone: input.timezone }),
        ...(input.currency !== undefined && {
          currency: input.currency.toUpperCase(),
        }),
        ...(input.locale !== undefined && { locale: input.locale }),
      },
      select: userSelect,
    });

    return user;
  },

  async googleLogin(idToken: string) {
    try {
      // 1. Verify the token with Firebase using the Modular API
      const decodedToken = await getAuth().verifyIdToken(idToken);
      const { email, name, uid } = decodedToken;
      
      if (!email) throw new Error('NO_EMAIL_FROM_GOOGLE');

      // 2. Check if user exists in our database
      let user = await prisma.user.findUnique({ where: { email } });

      // 3. If not, create a new user (no password needed since they use Google)
      if (!user) {
        // Generate a random password just in case they try to login normally later
        const randomPassword = await bcrypt.hash(uid + 'GoogleSecret!', SALT_ROUNDS);
        
        user = await prisma.user.create({
          data: {
            email: email,
            fullName: name || 'Google User',
            phone: `G-${uid.substring(0, 10)}`, // Placeholder phone
            password: randomPassword,
            role: 'CUSTOMER',
            status: 'ACTIVE',
          },
        });

        // Create the Customer profile
        await prisma.customer.create({ data: { userId: user.id } });
      }

      // 4. Generate our app's JWT token
      const token = signToken(user.id, user.role, user.isSuperAdmin);
      const { password: _omit, ...safeUser } = user;
      
      return { user: safeUser, token };
    } catch (error) {
      console.error('Google Auth Error:', error);
      throw new Error('INVALID_GOOGLE_TOKEN');
    }
  },
};