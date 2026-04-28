import React, { useState, useRef, useEffect } from 'react';
import { X, ChevronDown, Ruler, Check, Keyboard } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { toast } from 'sonner';
import { WeightRuler } from './WeightRuler';

interface WeightInputProps {
  initialWeight?: number;
  onClose: () => void;
  onSave: (weight: number) => void;
}

export const WeightInput: React.FC<WeightInputProps> = ({ 
  initialWeight = 62.00, 
  onClose, 
  onSave 
}) => {
  const [weight, setWeight] = useState(initialWeight.toFixed(2));
  const [unit, setUnit] = useState<'kg' | 'jin'>('kg');
  const [isFocused, setIsFocused] = useState(false);
  const [showRuler, setShowRuler] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!showRuler) {
      // 延迟聚焦以确保在动画进行中或完成后触发，提高移动端键盘唤起的可靠性
      const timer = setTimeout(() => {
        if (inputRef.current) {
          inputRef.current.focus();
          const len = inputRef.current.value.length;
          inputRef.current.setSelectionRange(len, len);
        }
      }, 500);
      return () => clearTimeout(timer);
    }
  }, [showRuler]);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    
    // 只允许数字和一个小数点
    if (value === '' || /^\d*\.?\d{0,2}$/.test(value)) {
      setWeight(value);
    }
  };

  const handleSave = () => {
    const numericWeight = parseFloat(weight);
    if (isNaN(numericWeight) || numericWeight <= 0) {
      toast.error("请输入有效的体重数值");
      return;
    }
    onSave(numericWeight);
    toast.success(`体重已更新为 ${numericWeight.toFixed(2)} ${unit === 'kg' ? '公斤' : '斤'}`);
  };

  return (
    <motion.div 
      initial={{ y: '100%' }}
      animate={{ y: 0 }}
      exit={{ y: '100%' }}
      transition={{ type: 'spring', damping: 25, stiffness: 200 }}
      className="fixed inset-0 z-[110] bg-white flex flex-col"
    >
      {/* Header */}
      <div className="flex items-center justify-between p-4 border-b border-slate-50">
        <div className="w-10"></div>
        <div className="flex items-center gap-1 bg-slate-50 px-3 py-1.5 rounded-full cursor-pointer active:bg-slate-100 transition-colors">
          <span className="text-sm font-medium text-slate-700">今天 18:23</span>
          <ChevronDown className="w-4 h-4 text-slate-400" />
        </div>
        <button 
          onClick={onClose}
          className="w-10 h-10 flex items-center justify-center rounded-full text-slate-300 hover:text-slate-500 transition-colors"
        >
          <X className="w-6 h-6" />
        </button>
      </div>

      {/* Main Display */}
      <div 
        className="flex-1 flex flex-col items-center justify-center px-6 cursor-pointer"
        onClick={() => !showRuler && inputRef.current?.focus()}
      >
        <div className="relative mb-2 flex items-center gap-4">
          <input
            ref={inputRef}
            type="text"
            inputMode="decimal"
            readOnly={showRuler}
            value={weight}
            onChange={handleInputChange}
            onFocus={() => setIsFocused(true)}
            onBlur={() => setIsFocused(false)}
            className="text-[64px] font-bold text-[#36c79a] tracking-tight leading-none text-center bg-transparent border-none outline-none w-[240px] placeholder:text-[#36c79a]/30"
            placeholder="0.00"
          />
          
          <div className="flex bg-slate-100 p-0.5 rounded-lg">
            <button 
              onClick={(e) => { e.stopPropagation(); setUnit('kg'); }}
              className={`px-2 py-1 text-[10px] font-bold rounded-md transition-all ${unit === 'kg' ? 'bg-[#36c79a] text-white shadow-sm' : 'text-slate-400'}`}
            >
              公斤
            </button>
            <button 
              onClick={(e) => { e.stopPropagation(); setUnit('jin'); }}
              className={`px-2 py-1 text-[10px] font-bold rounded-md transition-all ${unit === 'jin' ? 'bg-[#36c79a] text-white shadow-sm' : 'text-slate-400'}`}
            >
              斤
            </button>
          </div>
        </div>
        
        <div className="h-[2px] w-48 bg-[#36c79a]/20 relative">
          <motion.div 
            className="absolute inset-0 bg-[#36c79a] w-1/2 mx-auto"
            animate={{ scaleX: (isFocused || showRuler) ? 1.2 : 1 }}
            transition={{ duration: 0.2 }}
          ></motion.div>
        </div>

        <AnimatePresence>
          {showRuler && (
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 20 }}
              className="w-full"
            >
              <WeightRuler 
                value={parseFloat(weight) || 62} 
                onChange={(val) => setWeight(val.toFixed(2))} 
              />
            </motion.div>
          )}
        </AnimatePresence>

        <span className="mt-4 text-[#36c79a] font-medium text-sm tracking-widest uppercase">
          {showRuler ? '滑动尺码' : '手动输入'}
        </span>
        
        <div className="mt-4 text-slate-400 text-sm">
          {showRuler ? '左右滑动精准调节体重' : '请输入您的体重数据'}
        </div>
      </div>

      {/* Bottom Actions */}
      <div className="p-6 pb-8 space-y-3">
        <button 
          onClick={() => setShowRuler(!showRuler)}
          className="w-full bg-slate-100 hover:bg-slate-200 active:scale-98 transition-all rounded-2xl p-4 flex items-center justify-center gap-2 text-slate-600 shadow-sm"
        >
          {showRuler ? (
            <>
              <Keyboard className="w-5 h-5 text-emerald-500" />
              <span className="font-bold">键盘输入</span>
            </>
          ) : (
            <>
              <Ruler className="w-5 h-5 text-emerald-500" />
              <span className="font-bold">滑尺输入</span>
            </>
          )}
        </button>
        
        <button 
          onClick={handleSave}
          className="w-full bg-[#36c79a] hover:bg-[#2eb189] active:scale-98 transition-all rounded-2xl p-4 flex items-center justify-center gap-2 text-white shadow-lg shadow-emerald-100"
        >
          <Check className="w-5 h-5" />
          <span className="text-lg font-bold">保存</span>
        </button>
      </div>
    </motion.div>
  );
};