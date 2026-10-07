import type { Response, NextFunction } from 'express';
import type { Request } from 'express';

export function requireDriver(req: Request, res: Response, next: NextFunction): void {
  const user = (req as any).user;

  if (!user) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  if (user.role !== 'DRIVER') {
    res.status(403).json({ success: false, message: 'Driver access required' });
    return;
  }

  next();
}