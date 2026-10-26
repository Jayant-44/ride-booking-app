import type { Request, Response } from 'express';

import { ValidationError } from '@/config/errors/errors.js';
import { customParse } from '@/lib/zod.js';

import { DriverAppService } from './service.js';
import { ProgressRideSchema, RejectAssignmentSchema } from './schemas.js';

function getUserId(req: Request): string | null {
  return (req as any).user?.id ?? null;
}

export async function listMyAssignmentsController(req: Request, res: Response): Promise<void> {
  const userId = getUserId(req);
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  try {
    const assignments = await DriverAppService.listMyAssignments(userId);
    res.success(assignments);
  } catch (err) {
    if (err instanceof Error && err.message === 'DRIVER_NOT_FOUND') {
      res.status(404).json({ success: false, message: 'Driver profile not found' });
      return;
    }
    throw err;
  }
}

export async function getAssignmentDetailController(req: Request, res: Response): Promise<void> {
  const userId = getUserId(req);
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  try {
    const assignment = await DriverAppService.getAssignmentDetail(
      userId,
      String(req.params.id)
    );
    res.success(assignment);
  } catch (err) {
    if (err instanceof Error && err.message === 'ASSIGNMENT_NOT_FOUND') {
      res.status(404).json({ success: false, message: 'Assignment not found' });
      return;
    }
    throw err;
  }
}

export async function acceptAssignmentController(
  req: Request,
  res: Response
): Promise<void> {
  const userId = getUserId(req);
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  try {
    const assignment = await DriverAppService.acceptAssignment(
      userId,
      String(req.params.id)
    );
    res.success(assignment, 'Assignment accepted');
  } catch (err) {
    if (err instanceof Error) {
      if (err.message === 'ASSIGNMENT_NOT_FOUND') {
        res.status(404).json({ success: false, message: 'Assignment not found' });
        return;
      }
      if (err.message === 'ASSIGNMENT_NOT_OFFERED') {
        res.status(400).json({
          success: false,
          message: 'Assignment is no longer pending',
        });
        return;
      }
      if (err.message === 'RIDE_ALREADY_TAKEN') {
        res.status(409).json({
          success: false,
          message: 'Another driver accepted this ride first',
        });
        return;
      }
    }
    throw err;
  }
}

export async function rejectAssignmentController(req: Request, res: Response): Promise<void> {
  const userId = getUserId(req);
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const validation = customParse(RejectAssignmentSchema, req.body ?? {});
  if (!validation.success) throw new ValidationError(validation.message);

  try {
    const assignment = await DriverAppService.rejectAssignment(
      userId,
      String(req.params.id),
      validation.data.reason
    );
    res.success(assignment, 'Assignment rejected');
  } catch (err) {
    if (err instanceof Error && err.message === 'ASSIGNMENT_NOT_FOUND') {
      res.status(404).json({ success: false, message: 'Assignment not found' });
      return;
    }
    if (err instanceof Error && err.message === 'ASSIGNMENT_NOT_OFFERED') {
      res.status(400).json({ success: false, message: 'Assignment is no longer pending' });
      return;
    }
    throw err;
  }
}

export async function progressRideController(req: Request, res: Response): Promise<void> {
  const userId = getUserId(req);
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const validation = customParse(ProgressRideSchema, req.body);
  if (!validation.success) throw new ValidationError(validation.message);

  try {
    const ride = await DriverAppService.progressRide(
      userId,
      String(req.params.id),
      validation.data
    );
    res.success(ride, 'Ride status updated');
  } catch (err) {
    if (err instanceof Error && err.message === 'ASSIGNMENT_NOT_FOUND') {
      res.status(404).json({ success: false, message: 'Assignment not found' });
      return;
    }
    if (err instanceof Error && err.message === 'INVALID_STATUS_TRANSITION') {
      res.status(400).json({
        success: false,
        message: 'Invalid status transition. Follow the sequence: EN_ROUTE → ARRIVED → IN_PROGRESS → COMPLETED',
      });
      return;
    }
    throw err;
  }
}

export async function getProfileController(req: Request, res: Response): Promise<void> {
  const userId = (req as any).user?.id;
  if (!userId) { res.status(401).json({ success: false, message: 'Not authenticated' }); return; }
  
  try {
    const profile = await DriverAppService.getProfile(userId);
    res.success(profile);
  } catch (err) {
    if (err instanceof Error && err.message === 'DRIVER_NOT_FOUND') {
      res.status(404).json({ success: false, message: 'Driver profile not found' });
      return;
    }
    throw err;
  }
}