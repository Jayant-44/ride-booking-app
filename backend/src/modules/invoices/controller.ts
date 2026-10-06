import type { Request, Response } from 'express';

import { ValidationError } from '@/config/errors/errors.js';
import { customParse } from '@/lib/zod.js';

import { InvoiceService } from './service.js';
import { MarkPaidSchema } from './schemas.js';

function getUserId(req: Request): string | null {
  return (req as any).user?.id ?? null;
}

export async function listMyInvoicesController(
  req: Request,
  res: Response
): Promise<void> {
  const userId = getUserId(req);
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const invoices = await InvoiceService.getMyInvoices(userId);
  res.success(invoices);
}

export async function getInvoiceController(
  req: Request,
  res: Response
): Promise<void> {
  const userId = getUserId(req);
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  try {
    const invoice = await InvoiceService.getInvoiceById(
      userId,
      String(req.params.id)
    );
    res.success(invoice);
  } catch (err) {
    if (err instanceof Error && err.message === 'INVOICE_NOT_FOUND') {
      res.status(404).json({ success: false, message: 'Invoice not found' });
      return;
    }
    throw err;
  }
}

export async function markPaidController(
  req: Request,
  res: Response
): Promise<void> {
  const userId = getUserId(req);
  if (!userId) {
    res.status(401).json({ success: false, message: 'Not authenticated' });
    return;
  }

  const validation = customParse(MarkPaidSchema, req.body ?? {});
  if (!validation.success) throw new ValidationError(validation.message);

  try {
    const invoice = await InvoiceService.markAsPaid(
      userId,
      String(req.params.id),
      validation.data
    );
    res.success(invoice, 'Payment recorded');
  } catch (err) {
    if (err instanceof Error && err.message === 'INVOICE_NOT_FOUND') {
      res.status(404).json({ success: false, message: 'Invoice not found' });
      return;
    }
    if (err instanceof Error && err.message === 'INVOICE_ALREADY_PAID') {
      res.status(400).json({ success: false, message: 'Invoice already paid' });
      return;
    }
    throw err;
  }
}