import { useQuery } from '@tanstack/react-query';
import { Users, Calendar, FileText, TrendingUp } from 'lucide-react';
import { memberAPI } from '../lib/api';

export default function Dashboard() {
  const { data: membersData } = useQuery({
    queryKey: ['members'],
    queryFn: () => memberAPI.list().then(res => res.data),
  });

  const stats = [
    {
      name: 'Total Anggota',
      value: membersData?.data?.length || 0,
      icon: Users,
      color: 'bg-blue-500',
      change: '+12%',
    },
    {
      name: 'Anggota Aktif',
      value: membersData?.data?.filter(m => m.status === 'ACTIVE').length || 0,
      icon: TrendingUp,
      color: 'bg-green-500',
      change: '+8%',
    },
    {
      name: 'Event Bulan Ini',
      value: 5,
      icon: Calendar,
      color: 'bg-purple-500',
      change: '+2',
    },
    {
      name: 'Laporan Pending',
      value: 3,
      icon: FileText,
      color: 'bg-yellow-500',
      change: '-1',
    },
  ];

  return (
    <div className="px-4 sm:px-6 lg:px-8">
      <div className="mb-8">
        <h1 className="text-2xl font-semibold text-gray-900">Dashboard</h1>
        <p className="mt-2 text-sm text-gray-700">
          Ringkasan aktivitas laboratorium SAQ
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => {
          const Icon = stat.icon;
          return (
            <div
              key={stat.name}
              className="bg-white overflow-hidden shadow rounded-lg hover:shadow-md transition-shadow"
            >
              <div className="p-5">
                <div className="flex items-center">
                  <div className={`flex-shrink-0 rounded-md p-3 ${stat.color}`}>
                    <Icon className="h-6 w-6 text-white" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        {stat.name}
                      </dt>
                      <dd className="flex items-baseline">
                        <div className="text-2xl font-semibold text-gray-900">
                          {stat.value}
                        </div>
                        <div className="ml-2 flex items-baseline text-sm font-semibold text-green-600">
                          {stat.change}
                        </div>
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Recent Activity */}
      <div className="mt-8 grid grid-cols-1 gap-5 lg:grid-cols-2">
        {/* Recent Members */}
        <div className="bg-white shadow rounded-lg">
          <div className="px-4 py-5 sm:px-6 border-b border-gray-200">
            <h3 className="text-lg leading-6 font-medium text-gray-900">
              Anggota Terbaru
            </h3>
          </div>
          <div className="px-4 py-5 sm:p-6">
            <div className="flow-root">
              <ul className="-my-5 divide-y divide-gray-200">
                {membersData?.data?.slice(0, 5).map((member) => (
                  <li key={member.id} className="py-4">
                    <div className="flex items-center space-x-4">
                      <div className="flex-shrink-0">
                        <div className="h-10 w-10 rounded-full bg-blue-500 flex items-center justify-center text-white font-semibold">
                          {member.name.charAt(0)}
                        </div>
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-gray-900 truncate">
                          {member.name}
                        </p>
                        <p className="text-sm text-gray-500 truncate">
                          {member.nim}
                        </p>
                      </div>
                      <div>
                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                          {member.status}
                        </span>
                      </div>
                    </div>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="bg-white shadow rounded-lg">
          <div className="px-4 py-5 sm:px-6 border-b border-gray-200">
            <h3 className="text-lg leading-6 font-medium text-gray-900">
              Aksi Cepat
            </h3>
          </div>
          <div className="px-4 py-5 sm:p-6">
            <div className="space-y-3">
              <button className="w-full flex items-center justify-between px-4 py-3 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                <span className="text-sm font-medium text-gray-900">
                  Tambah Anggota Baru
                </span>
                <Users className="h-5 w-5 text-gray-400" />
              </button>
              <button className="w-full flex items-center justify-between px-4 py-3 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                <span className="text-sm font-medium text-gray-900">
                  Buat Laporan Harian
                </span>
                <FileText className="h-5 w-5 text-gray-400" />
              </button>
              <button className="w-full flex items-center justify-between px-4 py-3 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                <span className="text-sm font-medium text-gray-900">
                  Jadwalkan Event
                </span>
                <Calendar className="h-5 w-5 text-gray-400" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}