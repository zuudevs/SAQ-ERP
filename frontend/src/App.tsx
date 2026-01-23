import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import MemberList from './pages/MemberList';
import MemberRegister from './pages/MemberRegister';
import MemberProfile from './pages/MemberProfile';
import Layout from './components/Layout';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Layout />}>
            <Route index element={<Navigate to="/members" replace />} />
            <Route path="members" element={<MemberList />} />
            <Route path="members/register" element={<MemberRegister />} />
            <Route path="members/:id" element={<MemberProfile />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  );
}

export default App;