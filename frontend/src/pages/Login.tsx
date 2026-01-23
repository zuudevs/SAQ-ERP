import { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { Lock, User } from 'lucide-react';
import { api } from '../lib/api';

interface LoginRequest {
  nim: string;
  password: string;
}

interface LoginResponse {
  token: string;
  refresh_token: string;
  user_id: string;
  role: string;
  name: string; // ADDED
}

export default function Login() {
  const navigate = useNavigate();
  const [formData, setFormData] = useState<LoginRequest>({
    nim: '',
    password: '',
  });

  const mutation = useMutation({
    mutationFn: (data: LoginRequest) =>
      api.post<LoginResponse>('/auth/login', data),
    onSuccess: (response) => {
      const { token, refresh_token, user_id, role, name } = response.data;
      
      // Store auth data
      localStorage.setItem('token', token);
      localStorage.setItem('refresh_token', refresh_token);
      localStorage.setItem('user_id', user_id);
      localStorage.setItem('role', role);
      localStorage.setItem('user_name', name); // ADDED
      
      // Redirect to dashboard
      navigate('/members');
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    mutation.mutate(formData);
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div>
          <div className="mx-auto h-16 w-16 bg-blue-600 rounded-full flex items-center justify-center">
            <Lock className="h-8 w-8 text-white" />
          </div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            ERP Lab SAQ
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Masuk ke sistem manajemen laboratorium
          </p>
        </div>

        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          <div className="rounded-md shadow-sm space-y-4">
            <div>
              <label htmlFor="nim" className="sr-only">
                NIM
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <User className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  id="nim"
                  name="nim"
                  type="text"
                  required
                  value={formData.nim}
                  onChange={handleChange}
                  className="appearance-none rounded-lg relative block w-full px-3 py-3 pl-10 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
                  placeholder="NIM (default: NIM sebagai password)"
                />
              </div>
            </div>

            <div>
              <label htmlFor="password" className="sr-only">
                Password
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Lock className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  id="password"
                  name="password"
                  type="password"
                  required
                  value={formData.password}
                  onChange={handleChange}
                  className="appearance-none rounded-lg relative block w-full px-3 py-3 pl-10 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
                  placeholder="Password"
                />
              </div>
            </div>
          </div>

          {mutation.error && (
            <div className="rounded-md bg-red-50 border border-red-200 p-4">
              <p className="text-sm text-red-800">
                NIM atau password salah. Silakan coba lagi.
              </p>
            </div>
          )}

          <div>
            <button
              type="submit"
              disabled={mutation.isPending}
              className="group relative w-full flex justify-center py-3 px-4 border border-transparent text-sm font-medium rounded-lg text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              {mutation.isPending ? 'Memproses...' : 'Masuk'}
            </button>
          </div>

          <div className="text-center">
            <p className="text-sm text-gray-600">
              Belum punya akun?{' '}
              <a href="/members/register" className="font-medium text-blue-600 hover:text-blue-500">
                Daftar di sini
              </a>
            </p>
          </div>
        </form>
      </div>
    </div>
  );
}