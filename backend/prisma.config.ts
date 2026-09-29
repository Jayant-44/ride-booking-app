import path from 'node:path';
import { config } from 'dotenv';
import { defineConfig } from 'prisma/config';

// Cargar .env desde la raíz del proyecto
config({ path: path.join(import.meta.dirname, '.env') });

export default defineConfig({
	schema: path.join(import.meta.dirname, 'prisma', 'schema.prisma'),
	migrations: {
		path: path.join(import.meta.dirname, 'prisma', 'migrations'),
	},
	datasource: {
		url: process.env.DATABASE_URL!,
	},
});
