import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080/api/v1';

export const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add request interceptor for auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Add response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Handle unauthorized
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Member API Types
export type Member = {
  id: string;
  nim: string;
  name: string;
  email_uni: string;
  generation_year: number;
  major_code: string;
  serial_number: number;
  status: string;
  member_role: string; // Changed from current_role
  joined_at: string;
  updated_at: string;
};

export type RegisterMemberRequest = {
  nim: string;
  name: string;
  email_uni: string;
  generation_year: number;
  major_code: string;
  serial_number: number;
};

export const memberAPI = {
  register: (data: RegisterMemberRequest) =>
    api.post<Member>('/members', data),
  
  getProfile: (id: string) =>
    api.get<Member>(`/members/${id}`),
  
  updateProfile: (id: string, data: Partial<Member>) =>
    api.put<Member>(`/members/${id}`, data),
  
  list: (page = 1, pageSize = 10) =>
    api.get<{ data: Member[]; meta: { page: number; page_size: number } }>(
      `/members?page=${page}&page_size=${pageSize}`
    ),
};