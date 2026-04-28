import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Mail, Lock, ArrowRight, MessageSquare } from 'lucide-react';
import { useNavigate } from 'react-router';

export const Login: React.FC = () => {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  React.useEffect(() => {
    const isAuthenticated = localStorage.getItem('isAuthenticated');
    if (isAuthenticated) {
      navigate('/');
    }
  }, [navigate]);

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    // Simulate login
    setTimeout(() => {
      localStorage.setItem('isAuthenticated', 'true');
      setIsLoading(false);
      navigate('/');
    }, 1500);
  };

  return (
    <div className="min-h-screen bg-white flex flex-col items-center px-8 pt-12 pb-8 overflow-hidden relative">
      {/* Background Decorative Circles */}
      <div className="absolute top-[-10%] right-[-20%] w-[300px] h-[300px] bg-emerald-50 rounded-full blur-3xl opacity-60" />
      <div className="absolute bottom-[-5%] left-[-10%] w-[250px] h-[250px] bg-emerald-100/30 rounded-full blur-3xl opacity-50" />

      {/* Title */}
      <motion.div 
        initial={{ opacity: 0, x: -20 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ delay: 0.2 }}
        className="w-full text-left mb-10 pt-10"
      >
        <h1 className="text-[32px] font-black text-slate-900 leading-tight">
          开启你的<br />
          <span className="text-[#36c79a]">健康旅程</span>
        </h1>
        <p className="text-slate-400 mt-2 font-medium">登录以同步您的运动与饮食数据</p>
      </motion.div>

      {/* Form */}
      <motion.form 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4 }}
        onSubmit={handleLogin}
        className="w-full space-y-4"
      >
        <div className="relative group">
          <div className="absolute inset-y-0 left-4 flex items-center pointer-events-none">
            <Mail className="w-5 h-5 text-slate-300 group-focus-within:text-[#36c79a] transition-colors" />
          </div>
          <input 
            type="email" 
            placeholder="电子邮箱"
            className="w-full bg-slate-50 border-2 border-transparent focus:border-[#36c79a]/20 focus:bg-white rounded-[20px] py-4 pl-12 pr-4 outline-none transition-all font-medium text-slate-700 placeholder:text-slate-300"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
        </div>

        <div className="relative group">
          <div className="absolute inset-y-0 left-4 flex items-center pointer-events-none">
            <Lock className="w-5 h-5 text-slate-300 group-focus-within:text-[#36c79a] transition-colors" />
          </div>
          <input 
            type="password" 
            placeholder="密码"
            className="w-full bg-slate-50 border-2 border-transparent focus:border-[#36c79a]/20 focus:bg-white rounded-[20px] py-4 pl-12 pr-4 outline-none transition-all font-medium text-slate-700 placeholder:text-slate-300"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
        </div>

        <div className="flex justify-end pt-1">
          <button type="button" className="text-[13px] font-bold text-[#36c79a] active:opacity-60 transition-opacity">忘记密码？</button>
        </div>

        <button 
          disabled={isLoading}
          className={`w-full bg-[#36c79a] text-white py-4 rounded-[22px] font-bold text-[16px] shadow-lg shadow-emerald-200 flex items-center justify-center gap-2 active:scale-[0.98] transition-all relative overflow-hidden group ${isLoading ? 'opacity-80' : ''}`}
        >
          <AnimatePresence mode="wait">
            {isLoading ? (
              <motion.div 
                key="loader"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"
              />
            ) : (
              <motion.div 
                key="content"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                className="flex items-center gap-2"
              >
                立即登录
                <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
              </motion.div>
            )}
          </AnimatePresence>
        </button>
      </motion.form>

      {/* Divider */}
      <div className="w-full flex items-center gap-4 my-8 opacity-20">
        <div className="flex-1 h-[1px] bg-slate-400" />
        <span className="text-[12px] font-black text-slate-400 uppercase tracking-widest">或通过</span>
        <div className="flex-1 h-[1px] bg-slate-400" />
      </div>

      {/* Social Login */}
      <div className="w-full grid grid-cols-2 gap-3">
        {[
          {
            icon: (
              <svg viewBox="0 0 24 24" className="w-5 h-5" fill="currentColor">
                <path d="M8.691 2.188C3.891 2.188 0 5.476 0 9.53c0 2.212 1.17 4.203 3.002 5.55a.59.59 0 0 1 .213.665l-.39 1.48c-.019.07-.048.141-.048.213 0 .163.13.295.29.295a.326.326 0 0 0 .167-.054l1.903-1.114a.864.864 0 0 1 .717-.098 10.16 10.16 0 0 0 2.837.403c.276 0 .543-.027.811-.05-.857-2.578.064-5.432 2.496-7.164 1.361-.972 3.018-1.466 4.747-1.466.302 0 .601.02.895.057C16.58 3.975 12.929 2.188 8.691 2.188zm-1.95 3.138c.599 0 1.084.485 1.084 1.084s-.485 1.084-1.084 1.084c-.599 0-1.084-.485-1.084-1.084s.485-1.084 1.084-1.084zm4.547 0c.599 0 1.084.485 1.084 1.084s-.485 1.084-1.084 1.084c-.599 0-1.084-.485-1.084-1.084s.485-1.084 1.084-1.084zM15.297 9.5c-3.9 0-7.063 2.701-7.063 6.03 0 3.329 3.164 6.03 7.063 6.03.818 0 1.605-.116 2.34-.323a.705.705 0 0 1 .584.08l1.546.905a.262.262 0 0 0 .137.044c.131 0 .237-.106.237-.237 0-.059-.023-.116-.038-.172l-.317-1.204a.48.48 0 0 1 .172-.541C21.15 19.154 22.36 17.46 22.36 15.53c0-3.329-3.163-6.03-7.063-6.03zm-2.19 2.484c.488 0 .884.396.884.884s-.396.884-.884.884-.884-.396-.884-.884.396-.884.884-.884zm4.38 0c.488 0 .884.396.884.884s-.396.884-.884.884-.884-.396-.884-.884.396-.884.884-.884z"/>
              </svg>
            ),
            label: '微信登录',
            color: 'text-[#07c160]',
            bg: 'bg-[#07c160]/5 hover:bg-[#07c160]/10',
            border: 'hover:border-[#07c160]/20'
          },
          {
            icon: (
              <svg viewBox="0 0 24 24" className="w-5 h-5" fill="currentColor">
                <path d="M12.003 2C6.479 2 2 6.479 2 12.003c0 2.57.969 4.911 2.558 6.689l-1.67 3.71 4.096-1.367c1.384.764 2.977 1.201 4.67 1.201 5.524 0 10.003-4.479 10.003-10.003C22.006 6.479 17.527 2 12.003 2zm-4.37 8.32c.488 0 .884.396.884.884s-.396.884-.884.884-.884-.396-.884-.884.396-.884.884-.884zm4.37 0c.488 0 .884.396.884.884s-.396.884-.884.884-.884-.396-.884-.884.396-.884.884-.884zm4.37 0c.488 0 .884.396.884.884s-.396.884-.884.884-.884-.396-.884-.884.396-.884.884-.884z"/>
              </svg>
            ),
            label: 'QQ 登录',
            color: 'text-[#1d78f0]',
            bg: 'bg-[#1d78f0]/5 hover:bg-[#1d78f0]/10',
            border: 'hover:border-[#1d78f0]/20'
          },
          {
            icon: <Mail className="w-5 h-5" />,
            label: '邮箱登录',
            color: 'text-slate-500',
            bg: 'bg-slate-50 hover:bg-slate-100',
            border: 'hover:border-slate-200'
          },
          {
            icon: <MessageSquare className="w-5 h-5" />,
            label: '短信验证',
            color: 'text-[#36c79a]',
            bg: 'bg-[#36c79a]/5 hover:bg-[#36c79a]/10',
            border: 'hover:border-[#36c79a]/20'
          }
        ].map((social, i) => (
          <button
            key={i}
            className={`flex items-center justify-center gap-2.5 p-3.5 ${social.bg} ${social.color} rounded-[20px] transition-colors border border-transparent ${social.border}`}
          >
            {social.icon}
            <span className="text-[13px] font-bold">{social.label}</span>
          </button>
        ))}
      </div>

      <div className="mt-auto pt-8">
        <p className="text-[14px] text-slate-400 font-medium">
          还没有账号？ <button className="text-[#36c79a] font-black">立即注册</button>
        </p>
      </div>
    </div>
  );
};