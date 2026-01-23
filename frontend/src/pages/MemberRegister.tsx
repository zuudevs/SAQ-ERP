import { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft } from 'lucide-react';
import { memberAPI, type RegisterMemberRequest } from '../lib/api';

export default function MemberRegister() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  
  const [formData, setFormData] = useState<RegisterMemberRequest>({
    nim: '',
    name: '',
    email_uni: '',
    generation_year: new Date().getFullYear(),
    major_code: '',
    serial_number: 1,
  });

  const mutation = useMutation({
    mutationFn: memberAPI.register,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['members'] });
      navigate('/members');
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    mutation.mutate(formData);
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: name === 'generation_year' || name === 'serial_number' 
        ? parseInt(value) 
        : value
    }));
  };

  return (
    <div className="px-4 sm:px-6 lg:px-8">
      <div className="mb-6">
        <button
          onClick={() => navigate('/members')}
          className="inline-flex items-center text-sm text-gray-500 hover:text-gray-700"
        >
          <ArrowLeft className="mr-2 h-4 w-4" />
          Kembali
        </button>
      </div>

      <div className="max-w-2xl">
        <h1 className="text-2xl font-semibold text-gray-900">Registrasi Anggota Baru</h1>
        <p className="mt-2 text-sm text-gray-700">
          Isi formulir di bawah untuk mendaftarkan anggota baru
        </p>

        <form onSubmit={handleSubmit} className="mt-6 space-y-6">
          <div>
            <label htmlFor="nim" className="block text-sm font-medium text-gray-700">
              NIM
            </label>
            <input
              type="text"
              name="nim"
              id="nim"
              required
              value={formData.nim}
              onChange={handleChange}
              placeholder="2024-11-001"
              className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
            />
          </div>

          <div>
            <label htmlFor="name" className="block text-sm font-medium text-gray-700">
              Nama Lengkap
            </label>
            <input
              type="text"
              name="name"
              id="name"
              required
              value={formData.name}
              onChange={handleChange}
              className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
            />
          </div>

          <div>
            <label htmlFor="email_uni" className="block text-sm font-medium text-gray-700">
              Email Universitas
            </label>
            <input
              type="email"
              name="email_uni"
              id="email_uni"
              required
              value={formData.email_uni}
              onChange={handleChange}
              placeholder="nama@student.ac.id"
              className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
            />
          </div>

          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
            <div>
              <label htmlFor="generation_year" className="block text-sm font-medium text-gray-700">
                Tahun Angkatan
              </label>
              <input
                type="number"
                name="generation_year"
                id="generation_year"
                required
                value={formData.generation_year}
                onChange={handleChange}
                className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
              />
            </div>

            <div>
              <label htmlFor="major_code" className="block text-sm font-medium text-gray-700">
                Kode Jurusan
              </label>
              <select
                name="major_code"
                id="major_code"
                required
                value={formData.major_code}
                onChange={handleChange}
                className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
              >
                <option value="">Pilih Jurusan</option>
                <option value="11">Informatika (11)</option>
                <option value="12">Sistem Informasi (12)</option>
              </select>
            </div>
          </div>

          <div>
            <label htmlFor="serial_number" className="block text-sm font-medium text-gray-700">
              Nomor Urut
            </label>
            <input
              type="number"
              name="serial_number"
              id="serial_number"
              required
              value={formData.serial_number}
              onChange={handleChange}
              min="1"
              className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
            />
          </div>

          {mutation.error && (
            <div className="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded">
              Terjadi kesalahan saat mendaftarkan anggota
            </div>
          )}

          <div className="flex justify-end space-x-3">
            <button
              type="button"
              onClick={() => navigate('/members')}
              className="px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
            >
              Batal
            </button>
            <button
              type="submit"
              disabled={mutation.isPending}
              className="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50"
            >
              {mutation.isPending ? 'Menyimpan...' : 'Simpan'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}