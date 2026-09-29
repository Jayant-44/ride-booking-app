import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

import { prisma } from '@/lib/clients/prisma.js';

import type { RegisterInput, LoginInput } from './schemas.js';

const SALT_ROUNDS = 10;
const JWT_SECRET = process.env.JWT_SECRET ?? 'dev-secret-change-me';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN ?? '7d';

const userSelect = {
  id: true,
  email: true,
  fullName: true,
  phone: true,
  role: true,
  status: true,
  timezone: true,
  currency: true,
  locale: true,
  createdAt: true,
} as const;

function signToken(userId: string, role: string): string {
  return jwt.sign({ sub: userId, role }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN } as jwt.SignOptions);
}

export const AuthService = {
  async register(input: RegisterInput) {
    const existing = await prisma.user.findUnique({ where: { email: input.email } });
    if (existing) {
      throw new Error('EMAIL_ALREADY_EXISTS');
    }

    const hashedPassword = await bcrypt.hash(input.password, SALT_ROUNDS);

    const user = await prisma.user.create({
      data: {
        email: input.email,
        password: hashedPassword,
        fullName: input.fullName,
        phone: input.phone,
        role: input.role,
        timezone: input.timezone,
        currency: input.currency,
        locale: input.locale,
      },
      select: userSelect,
    });

    // Create role-specific record
    if (user.role === 'CUSTOMER') {
      await prisma.customer.create({ data: { userId: user.id } });
    }

    const token = signToken(user.id, user.role);
    return { user, token };
  },

  async login(input: LoginInput) {
    const user = await prisma.user.findUnique({ where: { email: input.email } });
    if (!user) {
      throw new Error('INVALID_CREDENTIALS');
    }

    const passwordMatches = await bcrypt.compare(input.password, user.password);
    if (!passwordMatches) {
      throw new Error('INVALID_CREDENTIALS');
    }

    const { password: _omit, ...safeUser } = user;
    const token = signToken(user.id, user.role);
    return { user: safeUser, token };
  },

  async me(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: userSelect,
    });
    if (!user) throw new Error('USER_NOT_FOUND');
    return user;
  },
};