import React, { useState, useEffect } from 'react';
import { X, ChevronDown, Delete, Check, Clock } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

interface QuickRecordProps {
  onClose: () => void;
  onSave: (data: { name: string; value: number; unit: string; time: string }) => void;
  title?: string;
}

const ITEMS = [
  { id: '1', name: '水', icon: '💧' },
  { id: '2', name: '茶水', icon: '🍵' },
  { id: '3', name: '苏打水', icon: '🥤' },
  { id: '4', name: '咖啡', icon: '☕' },
  { id: '5', name: '椰奶', icon: '🥥' },
  { id: '6', name: '柠檬水', icon: '🍋' },
  { id: '7', name: '苹果醋', icon: '🍎' },
  { id: '8', name: '红糖水', icon: '🥣' },
  { id: '9', name: '豆浆', icon: '🥛' },
  { id: '10', name: '粥', icon: '🍲' },
  { id: '11', name: '豆奶', icon: '🥛' },
  { id: '12', name: '可乐', icon: '🥤' },
  { id: '13', name: '牛奶', icon: '🥛' },
  { id: '14', name: '果汁', icon: '🍹' },
  { id: '15', name: '酸梅汤', icon: '🍷' },
  { id: '16', name: '酸奶', icon: '🍦' },
  { id: '17', name: '奶茶', icon: '🧋' },
  { id: '18', name: '养乐多', icon: '🍼' },
];

export const QuickRecord: React.FC<QuickRecordProps> = ({ onClose, onSave, title = "设置快捷记录" }) => {
  const [inputValue, setInputValue] = useState("350");
  const [selectedId, setSelectedId] = useState('1');
  const [time, setTime] = useState("");
  const [isFresh, setIsFresh] = useState(true);
  const [showTimePicker, setShowTimePicker] = useState(false);

  useEffect(() => {
    const now = new Date();
    const hh = String(now.getHours()).padStart(2, '0');
    const mm = String(now.getMinutes()).padStart(2, '0');
    setTime(`${hh}:${mm}`);
  }, []);

  const handleNumberClick = (num: string) => {
    if (isFresh || inputValue === "0") {
      setInputValue(num);
      setIsFresh(false);
    } else {
      if (inputValue.length < 5) {
        setInputValue(prev => prev + num);
      }
    }
  };

  const handleDelete = () => {
    setIsFresh(false);
    setInputValue(prev => prev.length > 1 ? prev.slice(0, -1) : "0");
  };

  const handleClear = () => {
    setInputValue("0");
    setIsFresh(false);
  };

  const handleComplete = () => {
    const item = ITEMS.find(i => i.id === selectedId);
    if (item) {
      onSave({
        name: item.name,
        value: parseInt(inputValue),
        unit: 'ml',
        time: time
      });
    }
  };

  const hours = Array.from({ length: 24 }, (_, i) => String(i).padStart(2, '0'));
  const minutes = Array.from({ length: 60 }, (_, i) => String(i).padStart(2, '0'));

  return (
    <motion.div
      initial={{ y: '100%' }}
      animate={{ y: 0 }}
      exit={{ y: '100%' }}
      transition={{ type: 'spring', damping: 25, stiffness: 200 }}
      className="fixed inset-0 z-[150] bg-white flex flex-col"
    >
      {/* Header */}
      <div className="flex items-center justify-between px-6 py-4 relative z-[160]">
        <span className="text-[17px] font-medium text-slate-800">{title}</span>
        
        {/* Time Picker Trigger */}
        <div 
          className="flex items-center gap-1 cursor-pointer bg-slate-50 px-3 py-1.5 rounded-full border border-slate-100 active:scale-95 transition-all"
          onClick={() => setShowTimePicker(!showTimePicker)}
        >
          <span className="text-[16px] font-bold text-slate-800 tracking-tight">{time}</span>
          <ChevronDown className={`w-4 h-4 text-slate-400 transition-transform ${showTimePicker ? 'rotate-180' : ''}`} />
        </div>

        <button onClick={onClose} className="p-1">
          <X className="w-6 h-6 text-slate-300" />
        </button>

        {/* Time Dropdown Menu */}
        <AnimatePresence>
          {showTimePicker && (
            <>
              <motion.div 
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                onClick={() => setShowTimePicker(false)}
                className="fixed inset-0 bg-black/10 z-[155]"
              />
              <motion.div
                initial={{ opacity: 0, y: -10, scale: 0.95 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: -10, scale: 0.95 }}
                className="absolute top-14 right-16 w-48 bg-white rounded-3xl shadow-2xl z-[160] overflow-hidden border border-slate-50"
              >
                <div className="flex h-48">
                  <div className="flex-1 overflow-y-auto no-scrollbar border-r border-slate-50">
                    <div className="text-[10px] text-center text-slate-400 py-1 sticky top-0 bg-white">小时</div>
                    {hours.map(h => (
                      <button 
                        key={h}
                        onClick={() => setTime(prev => `${h}:${prev.split(':')[1]}`)}
                        className={`w-full py-2 text-[15px] ${time.startsWith(h) ? 'bg-sky-50 text-sky-500 font-bold' : 'text-slate-500'}`}
                      >
                        {h}
                      </button>
                    ))}
                  </div>
                  <div className="flex-1 overflow-y-auto no-scrollbar">
                    <div className="text-[10px] text-center text-slate-400 py-1 sticky top-0 bg-white">分钟</div>
                    {minutes.map(m => (
                      <button 
                        key={m}
                        onClick={() => setTime(prev => `${prev.split(':')[0]}:${m}`)}
                        className={`w-full py-2 text-[15px] ${time.endsWith(m) ? 'bg-sky-50 text-sky-500 font-bold' : 'text-slate-500'}`}
                      >
                        {m}
                      </button>
                    ))}
                  </div>
                </div>
                <button 
                  onClick={() => setShowTimePicker(false)}
                  className="w-full py-3 bg-sky-400 text-white font-bold text-sm"
                >
                  确定
                </button>
              </motion.div>
            </>
          )}
        </AnimatePresence>
      </div>

      {/* Value Display */}
      <div className="flex flex-col items-center justify-center py-6">
        <button 
          onClick={handleClear}
          className="flex items-baseline gap-2 border-b-2 border-sky-300 pb-1 px-4 active:scale-95 transition-transform"
        >
          <span className={`text-[40px] font-bold tracking-tight ${isFresh ? 'text-slate-300' : 'text-slate-900'}`}>
            {inputValue}
          </span>
          <span className="text-[18px] font-bold text-sky-400">ml</span>
        </button>
      </div>

      {/* Items Grid */}
      <div className="flex-1 overflow-y-auto px-4 py-2 no-scrollbar">
        <div className="grid grid-cols-3 gap-3">
          {ITEMS.map((item) => (
            <button
              key={item.id}
              onClick={() => setSelectedId(item.id)}
              className={`flex items-center justify-center gap-2 py-3 rounded-[14px] transition-all border ${
                selectedId === item.id 
                  ? 'bg-sky-50 border-sky-400' 
                  : 'bg-slate-50 border-transparent'
              }`}
            >
              <span className="text-xl">{item.icon}</span>
              <span className={`text-[15px] ${selectedId === item.id ? 'text-sky-500 font-bold' : 'text-slate-600'}`}>
                {item.name}
              </span>
            </button>
          ))}
        </div>
      </div>

      {/* Number Pad */}
      <div className="bg-slate-50 p-2 pb-8 grid grid-cols-4 gap-2">
        <div className="col-span-3 grid grid-cols-3 gap-2">
          {['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '00'].map((num, i) => (
            num === '' ? <div key={i} /> : (
              <button
                key={i}
                onClick={() => handleNumberClick(num)}
                className="bg-white py-4 rounded-xl shadow-sm text-[24px] font-medium text-slate-800 active:bg-slate-100 transition-colors"
              >
                {num}
              </button>
            )
          ))}
        </div>
        <div className="grid grid-rows-2 gap-2">
          <button
            onClick={handleDelete}
            className="bg-white flex items-center justify-center rounded-xl shadow-sm active:bg-slate-100 transition-colors"
          >
            <div className="bg-slate-100 p-2 rounded-lg">
              <Delete className="w-6 h-6 text-slate-600" />
            </div>
          </button>
          <button
            onClick={handleComplete}
            className="bg-sky-400 flex items-center justify-center rounded-xl shadow-lg active:bg-sky-500 transition-colors"
          >
            <span className="text-white font-bold text-[18px]">完成</span>
          </button>
        </div>
      </div>
    </motion.div>
  );
};
