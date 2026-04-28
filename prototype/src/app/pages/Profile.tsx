import React from 'react';
import { 
  Settings, ChevronRight, User, Award, ShieldCheck, 
  HelpCircle, LogOut, Heart, Activity, Target, Share2 
} from 'lucide-react';
import { motion } from 'motion/react';
import { useNavigate } from 'react-router';
import { ImageWithFallback } from '../components/figma/ImageWithFallback';

const USER_AVATAR = "https://images.unsplash.com/photo-1544005313-94ddf0286df2?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxmZW1hbGUlMjBwcm9maWxlJTIwYXZhdGFyJTIwM2QlMjByZW5kZXJ8ZW58MXx8fHwxNzc0MjQ5NzIzfDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral";
const CHART_ICON = "https://images.unsplash.com/photo-1666875753105-c63a6f3bdc86?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHwzZCUyMGNoYXJ0JTIwYW5hbHl0aWNzJTIwaWNvbiUyMGhlYWx0aHxlbnwxfHx8fDE3NzYwNTk1NTZ8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral";
const SHIELD_ICON = "https://images.unsplash.com/photo-1638947604157-d259d219eeee?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHwzZCUyMHNoaWVsZCUyMHNlY3VyaXR5JTIwaWNvbiUyMGhlYWx0aHxlbnwxfHx8fDE3NzYwNTk1NTZ8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral";
const GIFT_ICON = "https://images.unsplash.com/photo-1760037034697-eee0b07ae072?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHwzZCUyMGdpZnQlMjByZXdhcmRzJTIwaWNvbiUyMGhlYWx0aHxlbnwxfHx8fDE3NzYwNTk1NTV8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral";

export const Profile: React.FC = () => {
  const navigate = useNavigate();

  const handleLogout = () => {
    localStorage.removeItem('isAuthenticated');
    navigate('/login');
  };

  const menuItems = [
    { icon: Activity, label: '周报分析', color: 'text-blue-500', bg: 'bg-blue-50', badge: 'NEW' },
    { icon: Target, label: '我的目标', color: 'text-orange-500', bg: 'bg-orange-50' },
    { icon: ShieldCheck, label: '账号安全', color: 'text-emerald-500', bg: 'bg-emerald-50' },
    { icon: HelpCircle, label: '帮助与反馈', color: 'text-slate-400', bg: 'bg-slate-50' },
  ];

  return (
    <div className="min-h-screen bg-[#f8fafc] pb-[100px] overflow-x-hidden">
      {/* Header Profile */}
      <div className="bg-gradient-to-br from-[#36c79a] to-[#8ef6d8] pt-16 pb-20 px-6 relative">
        <div className="absolute top-4 right-4">
          <button className="p-2 text-white/80 hover:text-white transition-colors">
            <Settings className="w-6 h-6" />
          </button>
        </div>

        <div className="flex items-center gap-4">
          <div className="relative w-20 h-20 border-4 border-white/30 rounded-full shadow-lg">
            <ImageWithFallback src={USER_AVATAR} className="w-full h-full rounded-full object-cover" />
            <div className="absolute -bottom-1 -right-1 bg-yellow-400 text-[10px] font-bold px-2 py-0.5 rounded-full border-2 border-white text-white">V3</div>
          </div>
          <div>
            <h1 className="text-2xl font-bold text-white mb-1">小明</h1>
            <div className="flex items-center gap-2">
              <div className="bg-white/20 px-3 py-0.5 rounded-full text-[11px] text-white font-bold backdrop-blur-sm">白金会员</div>
              <div className="flex items-center gap-1 text-white/90 text-[12px] font-medium">
                <Award className="w-3 h-3" />
                积分 1200
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Stats Summary Cards */}
      <div className="px-4 -mt-10">
        <div className="grid grid-cols-2 gap-4">
          <motion.div 
            whileHover={{ y: -5 }}
            className="bg-white p-5 rounded-[28px] shadow-sm border border-slate-50 relative overflow-hidden group"
          >
            <div className="relative z-10">
              <span className="text-slate-400 text-[12px] block mb-2">数据报告</span>
              <div className="text-[20px] font-bold text-slate-800 flex items-baseline gap-1">
                98 <span className="text-[12px] font-medium text-slate-400">分</span>
              </div>
            </div>
            <div className="absolute -right-2 -bottom-2 w-16 h-16 opacity-10 group-hover:opacity-20 transition-opacity">
              <ImageWithFallback src={CHART_ICON} className="w-full h-full object-contain" />
            </div>
          </motion.div>

          <motion.div 
            whileHover={{ y: -5 }}
            className="bg-white p-5 rounded-[28px] shadow-sm border border-slate-50 relative overflow-hidden group"
          >
            <div className="relative z-10">
              <span className="text-slate-400 text-[12px] block mb-2">会员权益</span>
              <div className="text-[20px] font-bold text-[#ff9d4d] flex items-baseline gap-1">
                8 <span className="text-[12px] font-medium text-slate-400">项</span>
              </div>
            </div>
            <div className="absolute -right-2 -bottom-2 w-16 h-16 opacity-10 group-hover:opacity-20 transition-opacity">
              <ImageWithFallback src={GIFT_ICON} className="w-full h-full object-contain" />
            </div>
          </motion.div>
        </div>
      </div>

      {/* Menu List */}
      <div className="px-4 mt-6">
        <div className="bg-white rounded-[28px] overflow-hidden shadow-sm border border-slate-50">
          {menuItems.map((item, i) => (
            <div 
              key={i} 
              className={`flex items-center gap-4 p-5 active:bg-slate-50 transition-colors cursor-pointer ${i < menuItems.length - 1 ? 'border-b border-slate-50' : ''}`}
            >
              <div className={`w-11 h-11 ${item.bg} rounded-[18px] flex items-center justify-center`}>
                <item.icon className={`w-6 h-6 ${item.color}`} strokeWidth={1.5} />
              </div>
              <span className="text-[16px] font-bold text-slate-800">{item.label}</span>
              <div className="ml-auto flex items-center gap-2">
                {item.badge && <div className="bg-rose-500 text-white text-[10px] font-black px-1.5 py-0.5 rounded-full">{item.badge}</div>}
                <ChevronRight className="w-5 h-5 text-slate-300" />
              </div>
            </div>
          ))}
        </div>

        <button 
          onClick={handleLogout}
          className="w-full mt-6 bg-white py-5 rounded-[28px] flex items-center justify-center gap-2 text-rose-500 font-bold text-[16px] shadow-sm border border-slate-50 active:scale-[0.98] transition-all"
        >
          <LogOut className="w-5 h-5" />
          退出登录
        </button>
      </div>

      <div className="mt-8 px-6 text-center">
        <p className="text-[12px] text-slate-300 font-medium">版本 2.4.0 (1024)</p>
      </div>
    </div>
  );
};
