import React, { useEffect } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router';
import { BottomNav } from './BottomNav';

export const Layout: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    const isAuthenticated = localStorage.getItem('isAuthenticated');
    if (!isAuthenticated && location.pathname !== '/login') {
      navigate('/login');
    }
  }, [navigate, location]);

  return (
    <div className="min-h-screen bg-[#f8fafc] flex justify-center">
      <div className="w-full max-w-md bg-white min-h-screen relative shadow-2xl shadow-slate-200/50">
        <Outlet />
        <BottomNav />
      </div>
    </div>
  );
};
