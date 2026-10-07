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

interface DriverVehicle {
  id: string;
  make: string;
  model: string;
  plateNo: string;
  color: string;
  capacity: number;
  luggageCapacity: number;
}

interface AvailableDriver {
  id: string;
  licenseNo: string;
  ratingAvg: number;
  totalTrips: number;
  user: { fullName: string; phone: string; email: string };
  vehicles: DriverVehicle[];
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
  DRIVER_OFFERED: 'Driver Offered',
  DRIVER_ASSIGNED: 'Driver Assigned',
  EN_ROUTE: 'En Route',
  ARRIVED: 'Arrived',
  IN_PROGRESS: 'In Progress',
  COMPLETED: 'Completed',
  REJECTED: 'Rejected',
  CANCELLED: 'Cancelled',
};

export default function Rides() {
  const queryClient = useQueryClient();
  const [invoiceRide, setInvoiceRide] = useState<Ride | null>(null);
  const [dispatchRide, setDispatchRide] = useState<Ride | null>(null);

  const { data, isLoading, isError, error } = useQuery({
    queryKey: ['admin', 'rides'],
    queryFn: async () => {
      const res = await api.get('/admin/rides');
      return res.data.data as Ride[];
    },
    refetchInterval: 10000,
  });

  const approveMutation = useMutation({
    mutationFn: (rideId: string) => api.patch(`/admin/rides/${rideId}/approve`),
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ['admin', 'rides'] }),
  });

  const rejectMutation = useMutation({
    mutationFn: (rideId: string) =>
      api.patch(`/admin/rides/${rideId}/reject`, { reason: 'Rejected by admin' }),
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ['admin', 'rides'] }),
  });

  const formatDate = (iso: string) =>
    new Date(iso).toLocaleString('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });

  const refresh = () =>
    queryClient.invalidateQueries({ queryKey: ['admin', 'rides'] });

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
                        onClick={() => rejectMutation.mutate(ride.id)}
                        disabled={rejectMutation.isPending}
                        className="px-3 py-1.5 bg-red-600 hover:bg-red-700 text-white text-xs font-medium rounded-lg disabled:opacity-50"
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
                      onClick={() => setDispatchRide(ride)}
                      className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-medium rounded-lg"
                    >
                      Assign Driver
                    </button>
                  )}

                  {ride.status === 'DRIVER_OFFERED' && (
                    <span className="text-xs text-indigo-600 font-medium">
                      Waiting for driver to accept
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
                  No rides yet. When a customer submits a ride request, it will
                  appear here.
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

      {dispatchRide && (
        <DispatchModal
          ride={dispatchRide}
          onClose={() => setDispatchRide(null)}
          onSuccess={() => {
            setDispatchRide(null);
            refresh();
          }}
        />
      )}
    </div>
  );
}

// ============================================================
// INVOICE MODAL (existing)
// ============================================================

interface InvoiceModalProps {
  ride: Ride;
  onClose: () => void;
  onSuccess: () => void;
}

function InvoiceModal({ ride, onClose, onSuccess }: InvoiceModalProps) {
  const [subtotal, setSubtotal] = useState('500');
  const [tax, setTax] = useState('90');
  const [currency, setCurrency] = useState('INR');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const subtotalCents = Math.round(parseFloat(subtotal || '0') * 100);
  const taxCents = Math.round(parseFloat(tax || '0') * 100);
  const totalCents = subtotalCents + taxCents;
  const currencySymbol =
    currency === 'INR' ? '₹' : currency === 'USD' ? '$' : currency + ' ';

  const handleSubmit = async () => {
    if (subtotalCents < 0 || taxCents < 0) {
      setError('Amounts cannot be negative');
      return;
    }
    if (totalCents === 0) {
      setError('Total must be greater than zero');
      return;
    }

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
      setError(err.response?.data?.message || 'Failed to create invoice');
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
            {ride.customer.user.fullName} ·{' '}
            {new Date(ride.scheduledAt).toLocaleDateString('en-IN')}
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
              <option value="EUR">EUR — €</option>
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
                min="0"
                step="0.01"
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
                min="0"
                step="0.01"
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
            className="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-50 rounded-lg"
          >
            Cancel
          </button>
          <button
            onClick={handleSubmit}
            disabled={loading}
            className="px-4 py-2 text-sm font-medium bg-blue-600 hover:bg-blue-700 text-white rounded-lg disabled:opacity-50"
          >
            {loading ? 'Sending...' : 'Send Invoice'}
          </button>
        </div>
      </div>
    </div>
  );
}

// ============================================================
// DISPATCH MODAL (new)
// ============================================================

interface DispatchModalProps {
  ride: Ride;
  onClose: () => void;
  onSuccess: () => void;
}

function DispatchModal({ ride, onClose, onSuccess }: DispatchModalProps) {
  const [assigningId, setAssigningId] = useState<string | null>(null);
  const [error, setError] = useState('');

  const { data, isLoading, isError } = useQuery({
    queryKey: ['admin', 'available-drivers', ride.id],
    queryFn: async () => {
      const res = await api.get(`/drivers/available/${ride.id}`);
      return res.data.data as AvailableDriver[];
    },
  });

  const assignMutation = useMutation({
    mutationFn: ({
      driverId,
      vehicleId,
    }: {
      driverId: string;
      vehicleId: string;
    }) =>
      api.post(`/drivers/assign/${ride.id}`, {
        driverId,
        vehicleId,
      }),
    onSuccess: () => onSuccess(),
    onError: (err: any) => {
      setError(err.response?.data?.message || 'Failed to assign driver');
      setAssigningId(null);
    },
  });

  const handleAssign = (driver: AvailableDriver) => {
    if (driver.vehicles.length === 0) {
      setError('This driver has no active vehicle');
      return;
    }
    setError('');
    setAssigningId(driver.id);
    assignMutation.mutate({
      driverId: driver.id,
      vehicleId: driver.vehicles[0].id,
    });
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl max-h-[90vh] flex flex-col">
        <div className="px-6 py-5 border-b border-slate-100 flex items-start justify-between">
          <div>
            <h2 className="text-lg font-bold text-slate-900">Assign Driver</h2>
            <p className="text-xs text-slate-500 mt-1">
              {ride.customer.user.fullName} ·{' '}
              {new Date(ride.scheduledAt).toLocaleString('en-IN', {
                day: '2-digit',
                month: 'short',
                hour: '2-digit',
                minute: '2-digit',
              })}
            </p>
          </div>
          <button
            onClick={onClose}
            className="text-slate-400 hover:text-slate-600 text-xl leading-none"
          >
            ×
          </button>
        </div>

        <div className="px-6 py-3 bg-slate-50 border-b border-slate-100 text-xs text-slate-600">
          <div className="truncate">
            <span className="text-emerald-600">●</span> {ride.pickupAddress}
          </div>
          <div className="truncate">
            <span className="text-red-600">●</span> {ride.dropoffAddress}
          </div>
        </div>

        <div className="flex-1 overflow-auto p-6">
          {isLoading && (
            <p className="text-sm text-slate-500 text-center py-8">
              Loading available drivers...
            </p>
          )}

          {isError && (
            <p className="text-sm text-red-600 text-center py-8">
              Failed to load available drivers
            </p>
          )}

          {!isLoading && !isError && data?.length === 0 && (
            <div className="text-center py-8">
              <p className="text-sm text-slate-500">
                No drivers available for this time slot.
              </p>
              <p className="text-xs text-slate-400 mt-2">
                All drivers may be busy or unavailable. Try a different time or
                add more drivers.
              </p>
            </div>
          )}

          {!isLoading && data && data.length > 0 && (
            <div className="space-y-3">
              {data.map((driver) => (
                <div
                  key={driver.id}
                  className="border border-slate-200 rounded-xl p-4 hover:border-slate-300 transition"
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="font-semibold text-slate-900">
                        {driver.user.fullName}
                      </div>
                      <div className="text-xs text-slate-500 mt-0.5">
                        {driver.user.phone}
                      </div>
                      <div className="text-xs text-slate-500 mt-0.5">
                        License: {driver.licenseNo} · Rating: {driver.ratingAvg.toFixed(1)} ⭐
                        {' · '}
                        {driver.totalTrips} trips
                      </div>
                    </div>
                    <button
                      onClick={() => handleAssign(driver)}
                      disabled={assigningId !== null}
                      className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-semibold rounded-lg disabled:opacity-50"
                    >
                      {assigningId === driver.id ? 'Assigning...' : 'Assign'}
                    </button>
                  </div>

                  {driver.vehicles.map((v) => (
                    <div
                      key={v.id}
                      className="mt-3 pt-3 border-t border-slate-100 text-xs text-slate-600"
                    >
                      🚗 {v.make} {v.model} · {v.color} · <span className="font-mono">{v.plateNo}</span>
                      {' · '}
                      {v.capacity} seats · {v.luggageCapacity} bags
                    </div>
                  ))}
                </div>
              ))}
            </div>
          )}

          {error && (
            <div className="mt-4 px-3 py-2 bg-red-50 border border-red-200 rounded-lg text-xs text-red-700">
              {error}
            </div>
          )}
        </div>

        <div className="px-6 py-4 border-t border-slate-100 flex justify-end">
          <button
            onClick={onClose}
            disabled={assigningId !== null}
            className="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-50 rounded-lg"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
}