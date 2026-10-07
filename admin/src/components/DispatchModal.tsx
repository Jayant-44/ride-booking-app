import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../lib/api';

interface Driver {
  id: string;
  licenseNo: string;
  ratingAvg: number;
  totalTrips: number;
  user: {
    fullName: string;
    phone: string;
    email: string;
  };
  vehicles: {
    id: string;
    make: string;
    model: string;
    plateNo: string;
    color: string;
    capacity: number;
    luggageCapacity: number;
  }[];
}

interface DispatchModalProps {
  rideId: string;
  rideSummary: string;
  onClose: () => void;
  onSuccess: () => void;
}

export default function DispatchModal({
  rideId,
  rideSummary,
  onClose,
  onSuccess,
}: DispatchModalProps) {
  const queryClient = useQueryClient();
  const [assigningId, setAssigningId] = useState<string | null>(null);
  const [error, setError] = useState('');

  const { data, isLoading, isError } = useQuery({
    queryKey: ['drivers', 'available', rideId],
    queryFn: async () => {
      const res = await api.get(`/drivers/available/${rideId}`);
      return res.data.data as Driver[];
    },
  });

  const assignMutation = useMutation({
    mutationFn: ({ driverId, vehicleId }: { driverId: string; vehicleId: string }) =>
      api.post(`/drivers/assign/${rideId}`, { driverId, vehicleId }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'rides'] });
      onSuccess();
    },
    onError: (err: any) => {
      setError(err.response?.data?.message || 'Failed to assign driver');
      setAssigningId(null);
    },
  });

  const handleAssign = (driver: Driver, vehicleId: string) => {
    setError('');
    setAssigningId(driver.id);
    assignMutation.mutate({ driverId: driver.id, vehicleId });
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl max-h-[90vh] flex flex-col">
        {/* Header */}
        <div className="px-6 py-5 border-b border-slate-100">
          <h2 className="text-lg font-bold text-slate-900">Assign Driver</h2>
          <p className="text-xs text-slate-500 mt-1">{rideSummary}</p>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-auto p-6">
          {isLoading && (
            <p className="text-sm text-slate-500 text-center py-8">
              Finding available drivers...
            </p>
          )}

          {isError && (
            <p className="text-sm text-red-600 text-center py-8">
              Failed to load available drivers
            </p>
          )}

          {data && data.length === 0 && (
            <div className="text-center py-12">
              <p className="text-slate-500 text-sm font-medium">
                No drivers available
              </p>
              <p className="text-slate-400 text-xs mt-2">
                Either all drivers are busy, or none have been added yet.
              </p>
            </div>
          )}

          {data && data.length > 0 && (
            <div className="space-y-3">
              {data.map((driver) => (
                <DriverRow
                  key={driver.id}
                  driver={driver}
                  assigning={assigningId === driver.id}
                  onAssign={handleAssign}
                />
              ))}
            </div>
          )}

          {error && (
            <div className="mt-4 px-3 py-2 bg-red-50 border border-red-200 rounded-lg text-xs text-red-700">
              {error}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-slate-100 flex justify-end">
          <button
            onClick={onClose}
            className="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-50 rounded-lg"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
}

// ============================================================
// DRIVER ROW
// ============================================================

interface DriverRowProps {
  driver: Driver;
  assigning: boolean;
  onAssign: (driver: Driver, vehicleId: string) => void;
}

function DriverRow({ driver, assigning, onAssign }: DriverRowProps) {
  const [selectedVehicle, setSelectedVehicle] = useState(
    driver.vehicles[0]?.id ?? ''
  );

  const vehicle = driver.vehicles.find((v) => v.id === selectedVehicle);

  return (
    <div className="border border-slate-200 rounded-xl p-4 hover:border-slate-300 transition">
      <div className="flex items-start gap-4">
        {/* Avatar */}
        <div className="w-11 h-11 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center font-bold text-sm flex-shrink-0">
          {driver.user.fullName
            .split(' ')
            .slice(0, 2)
            .map((s) => s[0]?.toUpperCase())
            .join('')}
        </div>

        {/* Info */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <h3 className="font-semibold text-slate-900 text-sm truncate">
              {driver.user.fullName}
            </h3>
            {driver.ratingAvg > 0 && (
              <span className="text-xs bg-amber-100 text-amber-800 px-2 py-0.5 rounded-full font-medium">
                ★ {driver.ratingAvg.toFixed(1)}
              </span>
            )}
          </div>
          <p className="text-xs text-slate-500 mt-0.5">{driver.user.phone}</p>
          <p className="text-xs text-slate-400 mt-0.5">
            {driver.totalTrips} trips · License {driver.licenseNo}
          </p>

          {/* Vehicle selector */}
          {driver.vehicles.length > 0 && (
            <div className="mt-3">
              <label className="block text-xs font-medium text-slate-600 mb-1">
                Vehicle
              </label>
              {driver.vehicles.length === 1 ? (
                <p className="text-xs text-slate-700">
                  {driver.vehicles[0].make} {driver.vehicles[0].model} ·{' '}
                  <span className="font-mono">
                    {driver.vehicles[0].plateNo}
                  </span>{' '}
                  · {driver.vehicles[0].color}
                </p>
              ) : (
                <select
                  value={selectedVehicle}
                  onChange={(e) => setSelectedVehicle(e.target.value)}
                  className="w-full text-xs border border-slate-300 rounded-lg px-2 py-1.5"
                >
                  {driver.vehicles.map((v) => (
                    <option key={v.id} value={v.id}>
                      {v.make} {v.model} · {v.plateNo} · {v.color}
                    </option>
                  ))}
                </select>
              )}
            </div>
          )}

          {vehicle && (
            <p className="text-xs text-slate-500 mt-1">
              Capacity {vehicle.capacity} pax · {vehicle.luggageCapacity} bags
            </p>
          )}
        </div>

        {/* Assign button */}
        <button
          onClick={() => onAssign(driver, selectedVehicle)}
          disabled={assigning || !selectedVehicle}
          className="px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-slate-400 text-white text-xs font-semibold rounded-lg transition flex-shrink-0"
        >
          {assigning ? 'Assigning...' : 'Assign'}
        </button>
      </div>
    </div>
  );
}