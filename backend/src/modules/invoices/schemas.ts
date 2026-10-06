import { z } from 'zod';

export const CreateInvoiceSchema = z.object({
  subtotalCents: z.number().int().min(0, 'Subtotal must be positive'),
  taxCents: z.number().int().min(0).default(0),
  currencyCode: z.string().length(3).default('INR'),
  dueAt: z.string().optional(),
});

export const MarkPaidSchema = z.object({
  paymentMethod: z.string().optional(),
  providerPaymentId: z.string().optional(),
});

export type CreateInvoiceInput = z.infer<typeof CreateInvoiceSchema>;
export type MarkPaidInput = z.infer<typeof MarkPaidSchema>;