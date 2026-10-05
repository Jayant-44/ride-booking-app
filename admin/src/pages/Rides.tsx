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
    user: {
      fullName: string;
      email: string;
      phone: string;
    };
  };
}

const STATUS_COLORS: Record<string, string> = {
  REQUESTED: 'New',
  ADMIN_REVIEW: 'Reviewed',
  QUOTED: 'Invoice Sent',
  AWAITING_PAYMENT: 'Awaiting Payment',
  CONFIRMED: 'Confirmed',
  DRIVER_OFFERED: 'Driver Offered',
  DRIVER_ASSIGNED: 'Driver Assigned',
  EN_ROUTE: 'Driver En Route',
  ARRIVED: 'Driver Arrived',
  IN_PROGRESS: 'In Progress',
  COMPLETED: 'Completed',
  REVIEWED: 'Reviewed',
  REJECTED: 'Rejected',
  CANCELLED: 'Cancelled',
};

export default function Rides() {
  const queryClient = useQueryClient();

  const { data, isLoading, isError, error } = useQuery({
    queryKey: ['admin', 'rides'],
    queryFn: async () => {
      const res = await api.get('/admin/rides');
      return res.data.data as Ride[];
    },
  });

  const approveMutation = useMutation({
    mutationFn: (rideId: string) =>
      api.patch(`/admin/rides/${rideId}/approve`),
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ['admin', 'rides'] }),
  });

  const rejectMutation = useMutation({
    mutationFn: (rideId: string) =>
      api.patch(`/admin/rides/${rideId}/reject`, {
        reason: 'Rejected by admin',
      }),
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
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-slate-900">Ride Requests</h1>
        <p className="text-sm text-slate-500 mt-1">{data?.length ?? 0} total</p>
      </div>

      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 border-b border-slate-200">
            <tr>
              <th className="text-left px-4 py-3 font-semibold text-slate-600">
                Scheduled
              </th>
              <th className="text-left px-4 py-3 font-semibold text-slate-600">
                Customer
              </th>
              <th className="text-left px-4 py-3 font-semibold text-slate-600">
                Route
              </th>
              <th className="text-left px-4 py-3 font-semibold text-slate-600">
                Details
              </th>
              <th className="text-left px-4 py-3 font-semibold text-slate-600">
                Status
              </th>
              <th className="text-left px-4 py-3 font-semibold text-slate-600">
                Actions
              </th>
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
                    <span className="text-emerald-600">●</span>{' '}
                    {ride.pickupAddress}
                  </div>
                  <div className="text-slate-700 truncate">
                    <span className="text-red-600">●</span>{' '}
                    {ride.dropoffAddress}
                  </div>
                </td>
                <td className="px-4 py-3 text-xs text-slate-600">
                  {ride.passengers} pax · {ride.luggageCount} bags
                  {ride.vehicleType && <div>{ride.vehicleType}</div>}
                </td>
                <td className="px-4 py-3">
                  <span
                    className={`inline-block px-2 py-1 rounded-full text-xs font-semibold ${
                      STATUS_COLORS[ride.status] ||
                      'bg-slate-100 text-slate-700'
                    }`}
                  >
                    {ride.status}
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
                        Mark Reviewed
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
                    <span className="text-xs text-slate-500">
                      Awaiting invoice
                    </span>
                  )}
                </td>
              </tr>
            ))}

            {data?.length === 0 && (
              <tr>
                <td
                  colSpan={6}
                  className="px-4 py-12 text-center text-slate-500"
                >
                  No rides yet. When a customer submits a ride request, it will
                  appear here.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}