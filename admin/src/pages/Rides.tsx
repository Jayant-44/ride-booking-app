import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../lib/api';

interface Ride {
  id: string;
  status: string;
  pickupAddress: string;
  dropoffAddress: string;
  scheduledAt: string;
  passengers: number;
  luggageCount: number;
  vehicleType: string | null;
  customer: {
    user: { fullName: string; email: string; phone: string };
  };
}

const STATUS_COLORS: Record<string, string> = {
  REQUESTED: 'bg-amber-100 text-amber-800',
  ADMIN_REVIEW: 'bg-blue-100 text-blue-800',
  QUOTED: 'bg-purple-100 text-purple-800',
  AWAITING_PAYMENT: 'bg-purple-100 text-purple-800',
  CONFIRMED: 'bg-emerald-100 text-emerald-800',
  DRIVER_OFFERED: 'bg-indigo-100 text-indigo-800',
  DRIVER_ASSIGNED: 'bg-teal-100 text-teal-800',
  EN_ROUTE: 'bg-sky-100 text-sky-800',
  ARRIVED: 'bg-sky-100 text-sky-800',
  IN_PROGRESS: 'bg-cyan-100 text-cyan-800',
  COMPLETED: 'bg-green-100 text-green-800',
  REJECTED: 'bg-red-100 text-red-800',
  CANCELLED: 'bg-slate-100 text-slate-700',
};

const STATUS_LABELS: Record<string, string> = {
  REQUESTED: 'New',
  ADMIN_REVIEW: 'Reviewed',
  QUOTED: 'Invoice Sent',
  AWAITING_PAYMENT: 'Awaiting Payment',
  CONFIRMED: 'Confirmed',
  DRIVER_OFFERED: 'Broadcast Sent',
  DRIVER_ASSIGNED: 'Driver Assigned',
  EN_ROUTE: 'On the Way',
  ARRIVED: 'Arrived',
  IN_PROGRESS: 'In Progress',
  COMPLETED: 'Completed',
  REJECTED: 'Rejected',
  CANCELLED: 'Cancelled',
};

export default function Rides() {
  const queryClient = useQueryClient();
  const [invoiceRide, setInvoiceRide] = useState<Ride | null>(null);
  const [rejectRide, setRejectRide] = useState<Ride | null>(null);

  const { data, isLoading, isError, error } = useQuery({
    queryKey: ['admin', 'rides'],
    queryFn: async () => {
      const res = await api.get('/admin/rides');
      return res.data.data as Ride[];
    },
    refetchInterval: 8000,
  });

  const refresh = () =>
    queryClient.invalidateQueries({ queryKey: ['admin', 'rides'] });

  const approveMutation = useMutation({
    mutationFn: (rideId: string) => api.patch(`/admin/rides/${rideId}/approve`),
    onSuccess: refresh,
  });

  const broadcastMutation = useMutation({
    mutationFn: (rideId: string) =>
      api.post(`/admin/rides/${rideId}/broadcast`),
    onSuccess: () => {
      refresh();
      alert('📢 Offer broadcast to all available drivers!');
    },
    onError: (err: any) => {
      alert(err.response?.data?.message || 'Broadcast failed');
    },
  });

  const formatDate = (iso: string) =>
    new Date(iso).toLocaleString('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });

  if (isLoading) {
    return (
      <div className="p-8">
        <p className="text-slate-500">Loading rides...</p>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="p-8">
        <p className="text-red-600">
          Failed to load rides: {(error as any)?.message}
        </p>
      </div>
    );
  }

  return (
    <div className="p-8">
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Ride Requests</h1>
          <p className="text-sm text-slate-500 mt-1">{data?.length ?? 0} total</p>
        </div>
        <button
          onClick={refresh}
          className="px-4 py-2 text-sm bg-white border border-slate-200 rounded-lg hover:bg-slate-50"
        >
          Refresh
        </button>
      </div>

      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 border-b border-slate-200">
            <tr>
              <th className="text-left px-4 py-3 font-semibold text-slate-600">Scheduled</th>
              <th className="text-left px-4 py-3 font-semibold text-slate-600">Customer</th>
              <th className="text-left px-4 py-3 font-semibold text-slate-600">Route</th>
              <th className="text-left px-4 py-3 font-semibold text-slate-600">Details</th>
              <th className="text-left px-4 py-3 font-semibold text-slate-600">Status</th>
              <th className="text-left px-4 py-3 font-semibold text-slate-600">Actions</th>
            </tr>
          </thead>
          <tbody>
            {data?.map((ride) => (
              <tr
                key={ride.id}
                className="border-b border-slate-100 last:border-0 hover:bg-slate-50"
              >
                <td className="px-4 py-3 whitespace-nowrap text-slate-700">
                  {formatDate(ride.scheduledAt)}
                </td>
                <td className="px-4 py-3">
                  <div className="font-medium text-slate-900">
                    {ride.customer.user.fullName}
                  </div>
                  <div className="text-xs text-slate-500">
                    {ride.customer.user.phone}
                  </div>
                </td>
                <td className="px-4 py-3 max-w-xs">
                  <div className="text-slate-700 truncate">
                    <span className="text-emerald-600">●</span> {ride.pickupAddress}
                  </div>
                  <div className="text-slate-700 truncate">
                    <span className="text-red-600">●</span> {ride.dropoffAddress}
                  </div>
                </td>
                <td className="px-4 py-3 text-xs text-slate-600">
                  {ride.passengers} pax · {ride.luggageCount} bags
                  {ride.vehicleType && <div>{ride.vehicleType}</div>}
                </td>
                <td className="px-4 py-3">
                  <span
                    className={`inline-block px-2 py-1 rounded-full text-xs font-semibold ${
                      STATUS_COLORS[ride.status] || 'bg-slate-100 text-slate-700'
                    }`}
                  >
                    {STATUS_LABELS[ride.status] ?? ride.status}
                  </span>
                </td>
                <td className="px-4 py-3">
                  {ride.status === 'REQUESTED' && (
                    <div className="flex gap-2">
                      <button
                        onClick={() => approveMutation.mutate(ride.id)}
                        disabled={approveMutation.isPending}
                        className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-medium rounded-lg disabled:opacity-50"
                      >
                        Approve
                      </button>
                      <button
                        onClick={() => setRejectRide(ride)}
                        className="px-3 py-1.5 bg-red-600 hover:bg-red-700 text-white text-xs font-medium rounded-lg"
                      >
                        Reject
                      </button>
                    </div>
                  )}

                  {ride.status === 'ADMIN_REVIEW' && (
                    <button
                      onClick={() => setInvoiceRide(ride)}
                      className="px-3 py-1.5 bg-blue-600 hover:bg-blue-700 text-white text-xs font-medium rounded-lg"
                    >
                      Send Invoice
                    </button>
                  )}

                  {ride.status === 'QUOTED' && (
                    <span className="text-xs text-slate-500">
                      Awaiting payment
                    </span>
                  )}

                  {ride.status === 'CONFIRMED' && (
                    <button
                      onClick={() => {
                        if (
                          confirm(
                            'Broadcast this ride to ALL available drivers? The first to accept gets it.'
                          )
                        ) {
                          broadcastMutation.mutate(ride.id);
                        }
                      }}
                      disabled={broadcastMutation.isPending}
                      className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-medium rounded-lg disabled:opacity-50"
                    >
                      {broadcastMutation.isPending
                        ? 'Broadcasting...'
                        : '📢 Broadcast to Drivers'}
                    </button>
                  )}

                  {ride.status === 'DRIVER_OFFERED' && (
                    <span className="text-xs text-indigo-600 font-medium">
                      Waiting for a driver...
                    </span>
                  )}

                  {ride.status === 'DRIVER_ASSIGNED' && (
                    <span className="text-xs text-teal-600 font-medium">
                      Driver accepted
                    </span>
                  )}
                </td>
              </tr>
            ))}

            {data?.length === 0 && (
              <tr>
                <td colSpan={6} className="px-4 py-12 text-center text-slate-500">
                  No rides yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {invoiceRide && (
        <InvoiceModal
          ride={invoiceRide}
          onClose={() => setInvoiceRide(null)}
          onSuccess={() => {
            setInvoiceRide(null);
            refresh();
          }}
        />
      )}

      {rejectRide && (
        <RejectModal
          ride={rejectRide}
          onClose={() => setRejectRide(null)}
          onSuccess={() => {
            setRejectRide(null);
            refresh();
          }}
        />
      )}
    </div>
  );
}

// ============================================================
// INVOICE MODAL
// ============================================================

function InvoiceModal({
  ride,
  onClose,
  onSuccess,
}: {
  ride: Ride;
  onClose: () => void;
  onSuccess: () => void;
}) {
  const [subtotal, setSubtotal] = useState('500');
  const [tax, setTax] = useState('90');
  const [currency, setCurrency] = useState('INR');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const subtotalCents = Math.round(parseFloat(subtotal || '0') * 100);
  const taxCents = Math.round(parseFloat(tax || '0') * 100);
  const totalCents = subtotalCents + taxCents;
  const currencySymbol = currency === 'INR' ? '₹' : '$';

  const handleSubmit = async () => {
    setLoading(true);
    setError('');
    try {
      await api.post(`/admin/rides/${ride.id}/invoice`, {
        subtotalCents,
        taxCents,
        currencyCode: currency,
      });
      onSuccess();
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to send invoice');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md">
        <div className="px-6 py-5 border-b border-slate-100">
          <h2 className="text-lg font-bold text-slate-900">Send Invoice</h2>
          <p className="text-xs text-slate-500 mt-1">
            {ride.customer.user.fullName}
          </p>
        </div>
        <div className="p-6 space-y-4">
          <div className="bg-slate-50 rounded-lg p-3 text-xs text-slate-600">
            <div className="truncate">
              <span className="text-emerald-600">●</span> {ride.pickupAddress}
            </div>
            <div className="truncate">
              <span className="text-red-600">●</span> {ride.dropoffAddress}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Currency
            </label>
            <select
              value={currency}
              onChange={(e) => setCurrency(e.target.value)}
              className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm"
            >
              <option value="INR">INR — ₹</option>
              <option value="USD">USD — $</option>
            </select>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Subtotal
              </label>
              <input
                type="number"
                value={subtotal}
                onChange={(e) => setSubtotal(e.target.value)}
                className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Tax
              </label>
              <input
                type="number"
                value={tax}
                onChange={(e) => setTax(e.target.value)}
                className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm"
              />
            </div>
          </div>

          <div className="bg-slate-50 rounded-lg p-4 flex items-center justify-between">
            <span className="text-sm font-medium text-slate-600">Total</span>
            <span className="text-lg font-bold text-slate-900">
              {currencySymbol}
              {(totalCents / 100).toFixed(2)}
            </span>
          </div>

          {error && (
            <div className="px-3 py-2 bg-red-50 border border-red-200 rounded-lg text-xs text-red-700">
              {error}
            </div>
          )}
        </div>
        <div className="px-6 py-4 border-t border-slate-100 flex justify-end gap-3">
          <button
            onClick={onClose}
            disabled={loading}
            className="px-4 py-2 text-sm text-slate-600 hover:bg-slate-50 rounded-lg"
          >
            Cancel
          </button>
          <button
            onClick={handleSubmit}
            disabled={loading}
            className="px-4 py-2 text-sm bg-blue-600 hover:bg-blue-700 text-white rounded-lg disabled:opacity-50"
          >
            {loading ? 'Sending...' : 'Send Invoice'}
          </button>
        </div>
      </div>
    </div>
  );
}

// ============================================================
// REJECT MODAL
// ============================================================

function RejectModal({
  ride,
  onClose,
  onSuccess,
}: {
  ride: Ride;
  onClose: () => void;
  onSuccess: () => void;
}) {
  const [reason, setReason] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async () => {
    setLoading(true);
    setError('');
    try {
      await api.patch(`/admin/rides/${ride.id}/reject`, {
        reason: reason || 'Rejected by admin',
      });
      onSuccess();
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to reject');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md">
        <div className="px-6 py-5 border-b border-slate-100">
          <h2 className="text-lg font-bold text-slate-900">Reject Ride</h2>
          <p className="text-xs text-slate-500 mt-1">
            {ride.customer.user.fullName}
          </p>
        </div>
        <div className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Reason (optional)
            </label>
            <textarea
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              rows={3}
              placeholder="e.g. Vehicle not available for this route"
              className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm"
            />
          </div>
          {error && (
            <div className="px-3 py-2 bg-red-50 border border-red-200 rounded-lg text-xs text-red-700">
              {error}
            </div>
          )}
        </div>
        <div className="px-6 py-4 border-t border-slate-100 flex justify-end gap-3">
          <button
            onClick={onClose}
            disabled={loading}
            className="px-4 py-2 text-sm text-slate-600 hover:bg-slate-50 rounded-lg"
          >
            Cancel
          </button>
          <button
            onClick={handleSubmit}
            disabled={loading}
            className="px-4 py-2 text-sm bg-red-600 hover:bg-red-700 text-white rounded-lg disabled:opacity-50"
          >
            {loading ? 'Rejecting...' : 'Reject'}
          </button>
        </div>
      </div>
    </div>
  );
}