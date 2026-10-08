import 'dotenv/config';
import bcrypt from 'bcryptjs';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  throw new Error('DATABASE_URL is not set');
}

const adapter = new PrismaPg({ connectionString });
const prisma = new PrismaClient({ adapter });

const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

async function generateUniqueId(prefix: 'DRV' | 'ADM'): Promise<string> {
  for (let attempt = 0; attempt < 10; attempt++) {
    let id = `${prefix}-`;
    for (let i = 0; i < 8; i++) {
      id += ALPHABET[Math.floor(Math.random() * ALPHABET.length)];
    }
    const existing = await prisma.user.findUnique({ where: { uniqueId: id } });
    if (!existing) return id;
  }
  throw new Error('Could not generate a unique ID after 10 attempts');
}

async function main() {
  const existingAdmin = await prisma.user.findUnique({
    where: { email: 'admin@admin.com' },
  });

  if (existingAdmin) {
    await prisma.user.update({
      where: { id: existingAdmin.id },
      data: {
        isSuperAdmin: true,
        status: 'ACTIVE',
        uniqueId: existingAdmin.uniqueId ?? 'ADM-SUPER001',
      },
    });
    console.log('✅ Upgraded admin@admin.com to super admin');
    console.log('   Unique ID: ADM-SUPER001');
  } else {
    const hash = await bcrypt.hash('admin123', 10);
    await prisma.user.create({
      data: {
        email: 'admin@admin.com',
        phone: '+919000000000',
        fullName: 'Super Admin',
        password: hash,
        role: 'ADMIN',
        status: 'ACTIVE',
        isSuperAdmin: true,
        uniqueId: 'ADM-SUPER001',
        timezone: 'Asia/Kolkata',
        currency: 'INR',
        locale: 'en',
      },
    });
    console.log('✅ Created super admin');
    console.log('   Email:     admin@admin.com');
    console.log('   Unique ID: ADM-SUPER001');
    console.log('   Password:  admin123');
  }

  const usersNeedingIds = await prisma.user.findMany({
    where: {
      role: { in: ['DRIVER', 'ADMIN'] },
      uniqueId: null,
    },
  });

  for (const user of usersNeedingIds) {
    const prefix = user.role === 'DRIVER' ? 'DRV' : 'ADM';
    const uniqueId = await generateUniqueId(prefix);
    await prisma.user.update({
      where: { id: user.id },
      data: { uniqueId, status: 'ACTIVE' },
    });
    console.log(`✅ Assigned ${uniqueId} to ${user.email} (${user.role})`);
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });