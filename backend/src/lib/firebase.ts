import { readFileSync, existsSync } from 'fs';
import { resolve, isAbsolute } from 'path';

import {
  initializeApp,
  getApps,
  applicationDefault,
  cert,
} from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { getAuth } from 'firebase-admin/auth';

let initialized = false;

export function initFirebase() {
  if (initialized) return;
  if (getApps().length > 0) {
    initialized = true;
    return;
  }

  try {
    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH ?? '';

    if (serviceAccountPath) {
      const absolutePath = isAbsolute(serviceAccountPath)
        ? serviceAccountPath
        : resolve(process.cwd(), serviceAccountPath);

      if (existsSync(absolutePath)) {
        const serviceAccount = JSON.parse(readFileSync(absolutePath, 'utf-8'));
        initializeApp({
          credential: cert(serviceAccount),
          projectId:
            process.env.FIREBASE_PROJECT_ID ?? serviceAccount.project_id,
        });
        initialized = true;
        console.log('[firebase] Admin SDK initialized with service account');
        return;
      }
    }

    initializeApp({
      credential: applicationDefault(),
      projectId: process.env.FIREBASE_PROJECT_ID ?? 'ride-booking-app-a1b2c',
    });
    initialized = true;
    console.log('[firebase] Admin SDK initialized with ADC');
  } catch (err) {
    console.error('[firebase] Failed to initialize admin SDK:', err);
    console.warn(
      '[firebase] Push notifications disabled. Run `gcloud auth application-default login` if using ADC.'
    );
  }
}

export function isFirebaseReady(): boolean {
  return initialized && getApps().length > 0;
}

export function getMessagingClient() {
  return getMessaging();
}

export function getAuthClient() {
  return getAuth();
}