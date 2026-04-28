import React, { useState } from 'react';
import { Send, Sparkles, BrainCircuit, History, Bot, Apple, Footprints, Weight } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { ImageWithFallback } from '../components/figma/ImageWithFallback';

const ROBOT_AVATAR = "https://images.unsplash.com/photo-1768400730875-d55297e10f29?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHwzZCUyMHJvYm90JTIwYXNzaXN0YW50JTIwYXZhdGFyJTIwaGVhbHRofGVufDF8fHx8MTc3NjA1OTU1Nnww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral";

export const AIAssistant: React.FC = () => {
  const [messages, setMessages] = useState([
    { id: 1, role: 'assistant', content: '嗨！我是你的 AI 健康助理。今天有什么想聊的吗？无论是饮食建议还是运动计划，我都在这。' },
  ]);
  const [inputValue, setInputValue] = useState('');

  const suggestions = [
    { icon: Apple, text: '分析今日早餐', color: 'bg-orange-50 text-orange-500' },
    { icon: Weight, text: '体重波动正常吗？', color: 'bg-emerald-50 text-emerald-500' },
    { icon: Footprints, text: '如何提高基础代谢', color: 'bg-blue-50 text-blue-500' },
  ];

  const handleSend = () => {
    if (!inputValue.trim()) return;
    
    const userMsg = { id: Date.now(), role: 'user', content: inputValue };
    setMessages(prev => [...prev, userMsg]);
    setInputValue('');

    // Mock AI Response
    setTimeout(() => {
      const aiMsg = { 
        id: Date.now() + 1, 
        role: 'assistant', 
        content: `针对“${userMsg.content}”，我的建议是保持规律作息，同时注意蛋白质的摄入。目前的体重趋势显示你正处于平台期，这很正常，建议增加 15 分钟的有氧运动。` 
      };
      setMessages(prev => [...prev, aiMsg]);
    }, 1000);
  };

  return (
    <div className="flex flex-col h-screen bg-[#f8fafc] pb-[100px]">
      {/* Header */}
      <div className="flex items-center gap-3 p-4 bg-white border-b border-slate-100 shrink-0">
        <div className="relative w-12 h-12">
          <ImageWithFallback src={ROBOT_AVATAR} alt="AI Avatar" className="w-full h-full rounded-full object-cover shadow-inner" />
          <div className="absolute -top-1 -right-1 w-4 h-4 bg-green-500 border-2 border-white rounded-full" />
        </div>
        <div>
          <h1 className="text-[17px] font-bold text-slate-800 flex items-center gap-2">
            AI 健康助理
            <Sparkles className="w-4 h-4 text-yellow-500 fill-current" />
          </h1>
          <p className="text-[12px] text-slate-400">正在思考如何帮你变美变瘦...</p>
        </div>
        <button className="ml-auto p-2 text-slate-400">
          <History className="w-6 h-6" />
        </button>
      </div>

      {/* Chat Area */}
      <div className="flex-1 overflow-y-auto p-4 space-y-6">
        <AnimatePresence initial={false}>
          {messages.map((msg) => (
            <motion.div
              key={msg.id}
              initial={{ opacity: 0, y: 10, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}
            >
              <div 
                className={`
                  max-w-[80%] px-5 py-3.5 rounded-[22px] text-[15px] leading-relaxed shadow-sm
                  ${msg.role === 'user' 
                    ? 'bg-gradient-to-r from-[#36c79a] to-[#8ef6d8] text-white rounded-br-none' 
                    : 'bg-white text-slate-700 rounded-bl-none border border-slate-50'
                  }
                `}
              >
                {msg.content}
              </div>
            </motion.div>
          ))}
        </AnimatePresence>
      </div>

      {/* Suggestions */}
      <div className="px-4 pb-4">
        <div className="flex gap-2 overflow-x-auto no-scrollbar py-2">
          {suggestions.map((item, i) => (
            <button 
              key={i}
              onClick={() => setInputValue(item.text)}
              className={`flex items-center gap-2 px-4 py-2.5 rounded-full whitespace-nowrap text-[13px] font-bold transition-all active:scale-95 ${item.color} shadow-sm border border-white/50`}
            >
              <item.icon className="w-4 h-4" />
              {item.text}
            </button>
          ))}
        </div>
      </div>

      {/* Input Box */}
      <div className="p-4 bg-white border-t border-slate-100 shadow-lg">
        <div className="flex items-center gap-2 bg-slate-50 p-2 rounded-[20px] border border-slate-100">
          <div className="w-9 h-9 flex items-center justify-center text-[#36c79a]">
            <BrainCircuit className="w-6 h-6" />
          </div>
          <input
            type="text"
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSend()}
            placeholder="输入您的问题..."
            className="flex-1 bg-transparent border-none outline-none text-[15px] text-slate-800 placeholder:text-slate-400 font-medium"
          />
          <button 
            onClick={handleSend}
            disabled={!inputValue.trim()}
            className={`w-9 h-9 rounded-full flex items-center justify-center transition-all ${inputValue.trim() ? 'bg-[#36c79a] text-white scale-100' : 'bg-slate-200 text-slate-400 scale-90 opacity-50'}`}
          >
            <Send className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
};
