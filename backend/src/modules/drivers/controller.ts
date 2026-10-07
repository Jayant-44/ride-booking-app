import type { Request, Response } from 'express';

import { ValidationError } from '@/config/errors/errors.js';
import { customParse } from '@/lib/zod.js';

import { DriverService } from './service.js';
import { CreateDriverSchema, AssignDriverSchema } from './schemas.js';

function getUserId(req: Request): string | null {
  return (req as any).user?.id ?? null;
}

export async function createDriverController(req: Request, res: Response): Promise<void> {
  const validation = customParse(CreateDriverSchema, req.body);
  if (!validation.success) throw new ValidationError(validation.message);

  try {
    const result = await DriverService.createDriver(validation.data);
    res.success(result, 'Driver created');
  } catch (err) {
    if (err instanceof Error && err.message === 'EMAIL_ALREADY_EXISTS') {
      res.status(409).json({ success: false, message: 'Email already registered' });
      return;
    }
    if (err instanceof Error && err.message === 'PLATE_ALREADY_EXISTS') {
      res.status(409).json({ success: false, message: 'Vehicle plate already registered' });
      return;
    }
    throw err;
  }
}

export async function listDriversController(_req: Request, res: Response): Promise<void> {
  const drivers = await DriverService.listDrivers();
  res.success(drivers);
}

export async function availableDriversController(req: Request, res: Response): Promise<void> {
  try {
    const drivers = await DriverService.getAvailableDriversForRide(String(req.params.id));
    res.success(drivers);
  } catch (err) {
    if (err instanceof Error && err.message === 'RIDE_NOT_FOUND') {
      res.status(404).json({ success: false, message: 'Ride not found' });
      return;
    }
    throw err;
  }
}

export async function assignDriverController(req: Request, res: Response): Promise<void> {
  const adminId = getUserId(req);
  if (!adminId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const validation = customParse(AssignDriverSchema, req.body);
  if (!validation.success) throw new ValidationError(validation.message);

  try {
    const assignment = await DriverService.assignDriver(
      adminId,
      String(req.params.id),
      validation.data.driverId,
      validation.data.vehicleId
    );
    res.success(assignment, 'Driver assigned');
  } catch (err) {
    if (err instanceof Error && err.message === 'RIDE_NOT_FOUND') {
      res.status(404).json({ success: false, message: 'Ride not found' });
      return;
    }
    if (err instanceof Error && err.message === 'RIDE_NOT_CONFIRMED') {
      res.status(400).json({ success: false, message: 'Ride must be confirmed first' });
      return;
    }
    if (err instanceof Error && err.message === 'DRIVER_DOUBLE_BOOKED') {
      res.status(409).json({ success: false, message: 'Driver is already booked during this time' });
      return;
    }
    throw err;
  }
}