import type { Request, Response } from 'express';

import { ValidationError } from '@/config/errors/errors.js';
import { customParse } from '@/lib/zod.js';

import { RideService } from './service.js';
import { CreateRideSchema, CancelRideSchema } from './schemas.js';

function getUserId(req: Request): string | null {
  return (req as any).user?.id ?? null;
}

export async function createRideController(
  req: Request,
  res: Response
): Promise<void> {
  const userId = getUserId(req);
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const validation = customParse(CreateRideSchema, req.body);
  if (!validation.success) throw new ValidationError(validation.message);

  try {
    const ride = await RideService.create(userId, validation.data);
    res.success(ride, 'Ride request created');
  } catch (err) {
    if (err instanceof Error && err.message === 'CUSTOMER_NOT_FOUND') {
      res
        .status(403)
        .json({ success: false, message: 'Customer profile not found' });
      return;
    }
    throw err;
  }
}

export async function listMyRidesController(
  req: Request,
  res: Response
): Promise<void> {
  const userId = getUserId(req);
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const rides = await RideService.listMy(userId);
  res.success(rides);
}

export async function getRideController(
  req: Request,
  res: Response
): Promise<void> {
  const userId = getUserId(req);
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  try {
    const ride = await RideService.getOne(userId, String(req.params.id));
    res.success(ride);
  } catch (err) {
    if (err instanceof Error && err.message === 'RIDE_NOT_FOUND') {
      res.status(404).json({ success: false, message: 'Ride not found' });
      return;
    }
    throw err;
  }
}

export async function cancelRideController(
  req: Request,
  res: Response
): Promise<void> {
  const userId = getUserId(req);
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const validation = customParse(CancelRideSchema, req.body ?? {});
  if (!validation.success) throw new ValidationError(validation.message);

  try {
    const ride = await RideService.cancel(
      userId,
      String(req.params.id),
      validation.data.reason
    );
    res.success(ride, 'Ride cancelled');
  } catch (err) {
    if (err instanceof Error && err.message === 'RIDE_NOT_FOUND') {
      res.status(404).json({ success: false, message: 'Ride not found' });
      return;
    }
    if (err instanceof Error && err.message === 'CANNOT_CANCEL') {
      res
        .status(400)
        .json({ success: false, message: 'Ride can no longer be cancelled' });
      return;
    }
    throw err;
  }
}