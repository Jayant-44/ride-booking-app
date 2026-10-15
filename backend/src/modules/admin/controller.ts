import type { Request, Response } from 'express';

import { ValidationError } from '@/config/errors/errors.js';
import { customParse } from '@/lib/zod.js';

import { AdminService } from './service.js';
import {
  ListRidesQuerySchema,
  RejectRideSchema,
  RejectUserSchema,
} from './schemas.js';

function getUserId(req: Request): string | null {
  return (req as any).user?.id ?? null;
}

function getActor(req: Request) {
  const user = (req as any).user;
  if (!user?.id) return null;
  return {
    id: user.id as string,
    isSuperAdmin: Boolean(user.isSuperAdmin),
  };
}

// ============================================================
// RIDES
// ============================================================

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
      res.status(400).json({
        success: false,
        message: 'Ride cannot be approved in its current state',
      });
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
    const ride = await AdminService.rejectRide(
      adminId,
      String(req.params.id),
      validation.data.reason
    );
    res.success(ride, 'Ride rejected');
  } catch (err) {
    if (err instanceof Error && err.message === 'RIDE_NOT_FOUND') {
      res.status(404).json({ success: false, message: 'Ride not found' });
      return;
    }
    if (err instanceof Error && err.message === 'RIDE_NOT_REJECTABLE') {
      res.status(400).json({
        success: false,
        message: 'Ride cannot be rejected in its current state',
      });
      return;
    }
    throw err;
  }
}

export async function statsController(_req: Request, res: Response): Promise<void> {
  const stats = await AdminService.getStats();
  res.success(stats);
}

// ============================================================
// INVOICES
// ============================================================

export async function createInvoiceController(
  req: Request,
  res: Response
): Promise<void> {
  const adminId = getUserId(req);
  if (!adminId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const { CreateInvoiceSchema } = await import('../invoices/schemas.js');
  const validation = customParse(CreateInvoiceSchema, req.body);
  if (!validation.success) throw new ValidationError(validation.message);

  try {
    const invoice = await AdminService.createInvoiceForRide(
      adminId,
      String(req.params.id),
      validation.data
    );
    res.success(invoice, 'Invoice created and sent');
  } catch (err) {
    if (err instanceof Error && err.message === 'RIDE_NOT_FOUND') {
      res.status(404).json({ success: false, message: 'Ride not found' });
      return;
    }
    if (err instanceof Error && err.message === 'RIDE_NOT_READY_FOR_INVOICE') {
      res.status(400).json({
        success: false,
        message: 'Ride must be marked as reviewed before creating an invoice',
      });
      return;
    }
    if (err instanceof Error && err.message === 'INVOICE_ALREADY_EXISTS') {
      res.status(409).json({
        success: false,
        message: 'An invoice already exists for this ride',
      });
      return;
    }
    throw err;
  }
}

// ============================================================
// USER APPROVALS (drivers & admins)
// ============================================================

export async function listPendingUsersController(
  req: Request,
  res: Response
): Promise<void> {
  const roleParam = req.query.role as string | undefined;
  const role =
    roleParam === 'DRIVER' || roleParam === 'ADMIN' ? roleParam : undefined;

  const users = await AdminService.listPendingUsers(role);
  res.success(users);
}

export async function approveUserController(
  req: Request,
  res: Response
): Promise<void> {
  const actor = getActor(req);
  if (!actor) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  try {
    const user = await AdminService.approveUser(
      actor.id,
      String(req.params.id),
      actor.isSuperAdmin
    );
    res.success(user, 'User approved');
  } catch (err) {
    if (err instanceof Error) {
      if (err.message === 'USER_NOT_FOUND') {
        res.status(404).json({ success: false, message: 'User not found' });
        return;
      }
      if (err.message === 'USER_NOT_PENDING') {
        res.status(400).json({
          success: false,
          message: 'User is not pending approval',
        });
        return;
      }
      if (err.message === 'SUPER_ADMIN_REQUIRED') {
        res.status(403).json({
          success: false,
          message: 'Only the super admin can approve new admins',
        });
        return;
      }
    }
    throw err;
  }
}

export async function rejectUserController(
  req: Request,
  res: Response
): Promise<void> {
  const actor = getActor(req);
  if (!actor) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const validation = customParse(RejectUserSchema, req.body ?? {});
  if (!validation.success) throw new ValidationError(validation.message);

  try {
    const user = await AdminService.rejectUser(
      actor.id,
      String(req.params.id),
      validation.data.reason,
      actor.isSuperAdmin
    );
    res.success(user, 'User rejected');
  } catch (err) {
    if (err instanceof Error) {
      if (err.message === 'USER_NOT_FOUND') {
        res.status(404).json({ success: false, message: 'User not found' });
        return;
      }
      if (err.message === 'SUPER_ADMIN_REQUIRED') {
        res.status(403).json({
          success: false,
          message: 'Only the super admin can reject new admins',
        });
        return;
      }
    }
    throw err;
  }
}

export async function broadcastRideController(
  req: Request,
  res: Response
): Promise<void> {
  const adminId = getUserId(req);
  if (!adminId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  try {
    const result = await AdminService.broadcastToDrivers(
      adminId,
      String(req.params.id)
    );
    res.success(result, `Offered to ${result.broadcast} driver(s)`);
  } catch (err) {
    if (err instanceof Error) {
      if (err.message === 'RIDE_NOT_FOUND') {
        res.status(404).json({ success: false, message: 'Ride not found' });
        return;
      }
      if (err.message === 'RIDE_NOT_CONFIRMED') {
        res.status(400).json({
          success: false,
          message: 'Ride must be paid and confirmed first',
        });
        return;
      }
      if (err.message === 'NO_DRIVERS_AVAILABLE') {
        res.status(400).json({
          success: false,
          message: 'No drivers available for this time slot',
        });
        return;
      }
    }
    throw err;
  }
}