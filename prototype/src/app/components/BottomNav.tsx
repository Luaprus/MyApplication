import React from 'react';
import { useNavigate, useLocation } from 'react-router';
import { Home as HomeIcon, BrainCircuit, User } from 'lucide-react';

export const BottomNav: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();

  const navItems = [
    { path: '/', icon: HomeIcon, label: '记录', id: 'home' },
    { path: '/ai', icon: BrainCircuit, label: 'AI', id: 'ai' },
    { path: '/profile', icon: User, label: '我的', id: 'profile' },
  ];

  return (
    <div className="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-md bg-white border-t border-slate-100 flex items-center justify-around py-2 px-6 pb-8 z-50">
      {navItems.map((item) => {
        const isActive = location.pathname === item.path;
        return (
          <div 
            key={item.id}
            onClick={() => navigate(item.path)}
            className={`flex flex-col items-center gap-1 group cursor-pointer transition-all duration-300 ${isActive ? 'scale-110' : 'opacity-50'}`}
          >
            <div className={`p-1 ${isActive ? 'text-[#36c79a]' : 'text-slate-900'}`}>
              <item.icon className={`w-6 h-6 ${isActive && item.id === 'home' ? 'fill-current' : ''}`} strokeWidth={isActive ? 2.5 : 1.5} />
            </div>
            <span className={`text-[12px] ${isActive ? 'font-bold text-[#36c79a]' : 'font-medium text-slate-900'}`}>
              {item.label}
            </span>
          </div>
        );
      })}
    </div>
  );
};
