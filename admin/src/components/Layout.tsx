import { NavLink, Outlet, useNavigate } from 'react-router-dom';

export default function Layout() {
  const navigate = useNavigate();

  const handleLogout = () => {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
    navigate('/login');
  };

  return (
    <div className="min-h-screen flex bg-slate-50">
      <aside className="w-64 bg-slate-900 text-slate-100 flex flex-col">
        <div className="p-6 border-b border-slate-800">
          <h1 className="text-lg font-bold">Ride Booking</h1>
          <p className="text-xs text-slate-400 mt-1">Admin Dashboard</p>
        </div>

        <nav className="flex-1 p-4 space-y-1">
          <NavLink
            to="/rides"
            className={({ isActive }: { isActive: boolean }) =>
              `block px-4 py-2 rounded-lg text-sm font-medium transition ${
                isActive
                  ? 'bg-slate-800 text-white'
                  : 'text-slate-300 hover:bg-slate-800 hover:text-white'
              }`
            }
          >
            Rides
          </NavLink>

          <NavLink
            to="/drivers"
            className={({ isActive }: { isActive: boolean }) =>
              `block px-4 py-2 rounded-lg text-sm font-medium transition ${
                isActive
                  ? 'bg-slate-800 text-white'
                  : 'text-slate-300 hover:bg-slate-800 hover:text-white'
              }`
            }
          >
            Drivers
          </NavLink>
        </nav>

        <div className="p-4 border-t border-slate-800">
          <button
            onClick={handleLogout}
            className="w-full px-4 py-2 text-sm bg-slate-800 hover:bg-slate-700 rounded-lg transition"
          >
            Log Out
          </button>
        </div>
      </aside>

      <main className="flex-1 overflow-auto">
        <Outlet />
      </main>
    </div>
  );
}