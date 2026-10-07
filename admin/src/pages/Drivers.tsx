import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../lib/api';

interface DriverRecord {
  id: string;
  licenseNo: string;
  licenseExpiry: string;
  status: string;
  ratingAvg: number;
  totalTrips: number;
  isAvailable: boolean;
  user: {
    id: string;
    fullName: string;
    email: string;
    phone: string;
    status: string;
  };
  vehicles: {
    id: string;
    make: string;
    model: string;
    plateNo: string;
    color: string;
    capacity: number;
    luggageCapacity: number;
    active: boolean;
  }[];
}

export default function Drivers() {
  const queryClient = useQueryClient();
  const [showForm, setShowForm] = useState(false);

  const { data, isLoading } = useQuery({
    queryKey: ['admin', 'drivers'],
    queryFn: async () => {
      const res = await api.get('/drivers');
      return res.data.data as DriverRecord[];
    },
  });

  if (isLoading) {
    return (
      <div className="p-8">
        <p className="text-slate-500">Loading drivers...</p>
      </div>
    );
  }

  return (
    <div className="p-8">
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Drivers</h1>
          <p className="text-sm text-slate-500 mt-1">
            {data?.length ?? 0} registered
          </p>
        </div>
        <button
          onClick={() => setShowForm(true)}
          className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold rounded-lg"
        >
          + Add Driver
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {data?.map((driver) => (
          <div
            key={driver.id}
            className="bg-white rounded-xl shadow-sm p-5 border border-slate-100"
          >
            <div className="flex items-start gap-3">
              <div className="w-12 h-12 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center font-bold flex-shrink-0">
                {driver.user.fullName
                  .split(' ')
                  .slice(0, 2)
                  .map((s) => s[0]?.toUpperCase())
                  .join('')}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <h3 className="font-semibold text-slate-900 truncate">
                    {driver.user.fullName}
                  </h3>
                  <span
                    className={`text-xs px-2 py-0.5 rounded-full font-medium ${
                      driver.isAvailable
                        ? 'bg-emerald-100 text-emerald-800'
                        : 'bg-slate-100 text-slate-600'
                    }`}
                  >
                    {driver.isAvailable ? 'Available' : 'Offline'}
                  </span>
                </div>
                <p className="text-xs text-slate-500 mt-0.5">
                  {driver.user.phone}
                </p>
                <p className="text-xs text-slate-400 mt-0.5">
                  {driver.user.email}
                </p>
                <p className="text-xs text-slate-500 mt-2">
                  License: <span className="font-mono">{driver.licenseNo}</span>
                </p>
                <p className="text-xs text-slate-500">
                  {driver.totalTrips} trips
                  {driver.ratingAvg > 0 &&
                    ` · ★ ${driver.ratingAvg.toFixed(1)}`}
                </p>

                {driver.vehicles.length > 0 && (
                  <div className="mt-3 pt-3 border-t border-slate-100">
                    {driver.vehicles.map((v) => (
                      <div key={v.id} className="text-xs text-slate-600">
                        <span className="font-medium">
                          {v.make} {v.model}
                        </span>{' '}
                        · <span className="font-mono">{v.plateNo}</span> ·{' '}
                        {v.color}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>
        ))}

        {data?.length === 0 && (
          <div className="col-span-full text-center py-16 text-slate-500">
            No drivers yet. Click "Add Driver" to register the first one.
          </div>
        )}
      </div>

      {showForm && (
        <AddDriverModal
          onClose={() => setShowForm(false)}
          onSuccess={() => {
            setShowForm(false);
            queryClient.invalidateQueries({ queryKey: ['admin', 'drivers'] });
          }}
        />
      )}
    </div>
  );
}

// ============================================================
// ADD DRIVER MODAL
// ============================================================

interface AddDriverModalProps {
  onClose: () => void;
  onSuccess: () => void;
}

function AddDriverModal({ onClose, onSuccess }: AddDriverModalProps) {
  const [form, setForm] = useState({
    email: '',
    password: 'driver123',
    fullName: '',
    phone: '',
    licenseNo: '',
    licenseExpiry: '2028-12-31',
    make: '',
    model: '',
    plateNo: '',
    color: 'White',
    capacity: 4,
    luggageCapacity: 2,
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const update = (key: string, value: string | number) =>
    setForm((f) => ({ ...f, [key]: value }));

  const handleSubmit = async () => {
    if (!form.email || !form.fullName || !form.phone || !form.licenseNo) {
      setError('Please fill all required fields');
      return;
    }
    if (!form.make || !form.model || !form.plateNo) {
      setError('Vehicle details are required');
      return;
    }

    setLoading(true);
    setError('');

    try {
      await api.post('/drivers', {
        email: form.email,
        password: form.password,
        fullName: form.fullName,
        phone: form.phone,
        licenseNo: form.licenseNo,
        licenseExpiry: new Date(form.licenseExpiry).toISOString(),
        vehicle: {
          make: form.make,
          model: form.model,
          plateNo: form.plateNo,
          color: form.color,
          capacity: Number(form.capacity),
          luggageCapacity: Number(form.luggageCapacity),
        },
      });
      onSuccess();
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to create driver');
    } finally {
      setLoading(false);
    }
  };

  const field = (
    label: string,
    key: string,
    type: string = 'text',
    placeholder?: string
  ) => (
    <div>
      <label className="block text-xs font-medium text-slate-700 mb-1">
        {label}
      </label>
      <input
        type={type}
        value={(form as any)[key]}
        onChange={(e) =>
          update(key, type === 'number' ? Number(e.target.value) : e.target.value)
        }
        placeholder={placeholder}
        className="w-full px-3 py-2 text-sm border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
      />
    </div>
  );

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl max-h-[90vh] flex flex-col">
        <div className="px-6 py-5 border-b border-slate-100">
          <h2 className="text-lg font-bold text-slate-900">Add New Driver</h2>
          <p className="text-xs text-slate-500 mt-1">
            Driver can log in with these credentials once created
          </p>
        </div>

        <div className="flex-1 overflow-auto p-6 space-y-5">
          <div>
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3">
              Account
            </h3>
            <div className="grid grid-cols-2 gap-3">
              {field('Full Name', 'fullName', 'text', 'Ramesh Kumar')}
              {field('Email', 'email', 'email', 'driver@example.com')}
              {field('Phone', 'phone', 'text', '+919111111111')}
              {field('Password', 'password', 'text', 'driver123')}
            </div>
          </div>

          <div>
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3">
              License
            </h3>
            <div className="grid grid-cols-2 gap-3">
              {field('License Number', 'licenseNo', 'text', 'DL-2024-123456')}
              {field('License Expiry', 'licenseExpiry', 'date')}
            </div>
          </div>

          <div>
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3">
              Vehicle
            </h3>
            <div className="grid grid-cols-2 gap-3">
              {field('Make', 'make', 'text', 'Maruti')}
              {field('Model', 'model', 'text', 'Swift Dzire')}
              {field('Plate Number', 'plateNo', 'text', 'DL-01-AB-1234')}
              {field('Color', 'color', 'text', 'White')}
              {field('Passenger Capacity', 'capacity', 'number')}
              {field('Luggage Capacity', 'luggageCapacity', 'number')}
            </div>
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
            className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold rounded-lg disabled:opacity-50"
          >
            {loading ? 'Creating...' : 'Create Driver'}
          </button>
        </div>
      </div>
    </div>
  );
}