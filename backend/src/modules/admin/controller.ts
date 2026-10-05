import type { Request, Response } from 'express';

import { ValidationError } from '@/config/errors/errors.js';
import { customParse } from '@/lib/zod.js';

import { AdminService } from './service.js';
import { ListRidesQuerySchema, RejectRideSchema } from './schemas.js';

function getUserId(req: Request): string | null {
  return (req as any).user?.id ?? null;
}

export async function listRidesController(req: Request, res: Response): Promise<void> {
  const validation = customParse(ListRidesQuerySchema, req.query);
  if (!validation.success) throw new ValidationError(validation.message);

  const rides = await AdminService.listRides(validation.data);
  res.success(rides);
}

export async function getRideController(req: Request, res: Response): Promise<void> {
  try {
    const ride = await AdminService.getRideById(String(req.params.id));
    res.success(ride);
  } catch (err) {
    if (err instanceof Error && err.message === 'RIDE_NOT_FOUND') {
      res.status(404).json({ success: false, message: 'Ride not found' });
      return;
    }
    throw err;
  }
}

export async function approveRideController(req: Request, res: Response): Promise<void> {
  const adminId = getUserId(req);
  if (!adminId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  try {
    const ride = await AdminService.approveRide(adminId, String(req.params.id));
    res.success(ride, 'Ride approved');
  } catch (err) {
    if (err instanceof Error && err.message === 'RIDE_NOT_FOUND') {
      res.status(404).json({ success: false, message: 'Ride not found' });
      return;
    }
    if (err instanceof Error && err.message === 'RIDE_NOT_APPROVABLE') {
      res.status(400).json({ success: false, message: 'Ride cannot be approved in its current state' });
      return;
    }
    throw err;
  }
}

export async function rejectRideController(req: Request, res: Response): Promise<void> {
  const adminId = getUserId(req);
  if (!adminId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const validation = customParse(RejectRideSchema, req.body ?? {});
  if (!validation.success) throw new ValidationError(validation.message);

  try {
    const ride = await AdminService.rejectRide(adminId, String(req.params.id), validation.data.reason);
    res.success(ride, 'Ride rejected');
  } catch (err) {
    if (err instanceof Error && err.message === 'RIDE_NOT_FOUND') {
      res.status(404).json({ success: false, message: 'Ride not found' });
      return;
    }
    if (err instanceof Error && err.message === 'RIDE_NOT_REJECTABLE') {
      res.status(400).json({ success: false, message: 'Ride cannot be rejected in its current state' });
      return;
    }
    throw err;
  }
}

export async function statsController(_req: Request, res: Response): Promise<void> {
  const stats = await AdminService.getStats();
  res.success(stats);
}