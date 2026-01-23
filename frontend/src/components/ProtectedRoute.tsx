import { Navigate } from 'react-router-dom';

interface ProtectedRouteProps {
  children: React.ReactNode;
  requiredRole?: string[];
}

// Updated App.tsx to include auth routes

export default function ProtectedRoute({ children, requiredRole }: ProtectedRouteProps) {
  const token = localStorage.getItem('token');
  const userRole = localStorage.getItem('role');

  // Check if user is authenticated
  if (!token) {
    return <Navigate to="/login" replace />;
  }

  // Check if user has required role
  if (requiredRole && requiredRole.length > 0) {
    if (!userRole || !requiredRole.includes(userRole)) {
      return (
        <div className="min-h-screen flex items-center justify-center bg-gray-50">
          <div className="max-w-md w-full bg-white shadow-lg rounded-lg p-6">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">
              Akses Ditolak
            </h2>
            <p className="text-gray-600 mb-4">
              Anda tidak memiliki izin untuk mengakses halaman ini.
            </p>
            <button
              onClick={() => window.history.back()}
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
            >
              Kembali
            </button>
          </div>
        </div>
      );
    }
  }

  return <>{children}</>;
}