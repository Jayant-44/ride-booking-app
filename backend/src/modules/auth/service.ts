import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

import { prisma } from '@/lib/clients/prisma.js';

import type {
  LoginInput,
  RegisterInput,
  DriverRegisterInput,
  AdminRegisterInput,
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
};