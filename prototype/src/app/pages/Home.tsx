import React, { useState, useEffect } from 'react';
import { 
  ChevronRight, Eye, Camera, Coffee, Pizza, Soup, Apple, Footprints, 
  Plus, Minus, Loader2, Send 
} from 'lucide-react';
import { ImageWithFallback } from '../components/figma/ImageWithFallback';
import { toast } from "sonner";
import { motion, AnimatePresence } from "motion/react";
import { WeightInput } from '../components/WeightInput';
import { ExerciseRecord } from '../components/ExerciseRecord';
import { QuickRecord } from '../components/QuickRecord';
import { CheckInCalendar } from '../components/CheckInCalendar';
import { aiService } from '../services/ai-service';

// --- Sub-components ---

interface HeaderProps {
  avatarUrl: string;
  onSendMessage: (msg: string) => void;
}

const Header: React.FC<HeaderProps> = ({ avatarUrl, onSendMessage }) => {
  const [inputValue, setInputValue] = useState("");
  const [isFocused, setIsFocused] = useState(false);

  const handleSend = () => {
    if (inputValue.trim()) {
      onSendMessage(inputValue);
      setInputValue("");
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleSend();
    }
  };

  return (
    <div className={`flex items-center gap-3 bg-white p-2 rounded-full shadow-sm mb-6 mt-2 transition-all duration-300 border ${isFocused ? 'border-emerald-200 ring-2 ring-emerald-50' : 'border-transparent'}`}>
      <div className="relative w-10 h-10 shrink-0">
        <ImageWithFallback
          src={avatarUrl}
          alt="AI Avatar"
          className="w-full h-full rounded-full object-cover"
        />
        <div className="absolute -top-1 -right-1 bg-black text-white text-[8px] px-1 rounded-sm font-bold">AI</div>
      </div>
      <div className="flex-1 flex items-center gap-2 pr-1">
        <input
          type="text"
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          onFocus={() => setIsFocused(true)}
          onBlur={() => setTimeout(() => setIsFocused(false), 200)}
          onKeyDown={handleKeyDown}
          placeholder="问问 AI：睡眠如何影响体重？"
          className="w-full bg-transparent border-none outline-none text-[15px] font-medium text-slate-800 placeholder:text-slate-400 placeholder:font-normal"
        />
        <button 
          onClick={handleSend}
          disabled={!inputValue.trim()}
          className={`w-9 h-9 rounded-full flex items-center justify-center transition-all ${inputValue.trim() ? 'bg-[#36c79a] text-white scale-100' : 'bg-slate-100 text-slate-300 scale-90 opacity-0'}`}
        >
          <Send className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
};

interface CheckInCardProps {
  onCheckIn: () => void;
  checked: boolean;
  onOpenDetails: () => void;
}

const CheckInCard: React.FC<CheckInCardProps> = ({ onCheckIn, checked, onOpenDetails }) => {
  return (
    <div className="rounded-[24px] overflow-hidden mb-6 shadow-sm transition-all active:scale-98">
      <div 
        className="bg-gradient-to-r from-[#b9f2e3] to-[#c7fceb] p-5 flex items-center justify-between cursor-pointer"
        onClick={onOpenDetails}
      >
        <div className="flex items-center gap-1 bg-white/40 px-3 py-1.5 rounded-full">
          <span className="text-[13px] font-medium text-slate-700">累计打卡</span>
          <span className="text-xl font-bold text-slate-900 mx-1">{checked ? 1 : 0}</span>
          <span className="text-[13px] font-medium text-slate-700">天</span>
        </div>
        <div className="flex items-center gap-1 bg-white/40 px-3 py-1.5 rounded-full">
          <span className="text-[13px] font-medium text-slate-700">连续打卡</span>
          <span className="text-xl font-bold text-slate-900 mx-1">{checked ? 1 : 0}</span>
          <span className="text-[13px] font-medium text-slate-700">天</span>
          <ChevronRight className="w-4 h-4 text-slate-500" />
        </div>
      </div>
      <div className="bg-white p-4 flex items-center justify-between">
        <p className="text-slate-500 text-[14px]">{checked ? "今日已完成打卡，真棒！" : "全力以赴，你会很酷"}</p>
        {!checked && (
          <button 
            onClick={(e) => {
              e.stopPropagation();
              onCheckIn();
            }}
            className="bg-[#36c79a] text-white text-[13px] font-bold px-4 py-2 rounded-full shadow-sm shadow-emerald-100"
          >
            立即打卡
          </button>
        )}
      </div>
    </div>
  );
};

const WeightPlanCard: React.FC = () => {
  return (
    <div className="bg-white rounded-[24px] p-6 shadow-sm mb-6">
      <div className="flex items-center justify-between mb-8">
        <div className="flex items-center gap-2">
          <span className="text-[17px] font-bold text-slate-800">体重管理方案</span>
          <Eye className="w-5 h-5 text-emerald-400" />
        </div>
        <div className="flex items-center gap-1">
          <span className="text-slate-500 text-sm">第</span>
          <div className="bg-[#e8fbf4] px-4 py-1 rounded-full text-[#36c79a] font-bold">1</div>
          <span className="text-slate-500 text-sm">周</span>
        </div>
      </div>

      <div className="relative flex justify-center items-end h-40 w-full">
        {/* 进度条圆弧容器 */}
        <div className="relative w-64 h-32">
          <svg viewBox="0 0 100 55" className="w-full h-full transform transition-all">
            {/* 灰色背景条 - 完整的半圆弧 */}
            <path
              id="bg-arc"
              d="M 10 50 A 40 40 0 0 1 90 50"
              fill="none"
              stroke="#f1f5f9"
              strokeWidth="10"
              strokeLinecap="round"
            />
            {/* 绿色进度条 - 引用同一路径确保不歪 */}
            <path
              d="M 10 50 A 40 40 0 0 1 90 50"
              fill="none"
              stroke="url(#gradient-arc-home)"
              strokeWidth="10"
              strokeLinecap="round"
              strokeDasharray="125.66"
              strokeDashoffset="87.96" 
              className="transition-all duration-1000 ease-out"
            />
            <defs>
              <linearGradient id="gradient-arc-home" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" stopColor="#36c79a" />
                <stop offset="100%" stopColor="#8ef6d8" />
              </linearGradient>
            </defs>
          </svg>

          {/* 中心数值 */}
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-2 text-center">
            <div className="text-[28px] font-bold text-slate-900 leading-none">0.10</div>
            <div className="text-[12px] text-slate-400 mt-1">已减去(公斤)</div>
          </div>
        </div>

        {/* 标签移动到卡片的最左右两侧 (脱离圆弧容器限制) */}
        <div className="absolute left-0 bottom-0 text-left">
          <div className="text-[18px] font-bold text-slate-900 leading-none">62.00</div>
          <div className="text-[12px] text-slate-400 mt-1">初始</div>
        </div>

        <div className="absolute right-0 bottom-0 text-right">
          <div className="text-[18px] font-bold text-slate-900 leading-none">61.90</div>
          <div className="text-[12px] text-slate-400 mt-1">目标</div>
        </div>
      </div>
    </div>
  );
};

const CalorieCard: React.FC<{ calories: number; onScan: () => void; onBreakfastClick: () => void }> = ({ calories, onScan, onBreakfastClick }) => {
  return (
    <div className="bg-white rounded-[24px] p-6 shadow-sm mb-6">
      <div className="flex items-center justify-between mb-8">
        <span className="text-[17px] font-bold text-slate-800">饮食热量</span>
        <div className="flex gap-1.5">
          <div className="w-1.5 h-1.5 rounded-full bg-slate-200"></div>
          <div className="w-1.5 h-1.5 rounded-full bg-emerald-400"></div>
          <div className="w-1.5 h-1.5 rounded-full bg-slate-200"></div>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-3 mb-8">
        <div className="flex flex-col">
          <span className="text-[12px] text-slate-400 mb-1">还可吃</span>
          <div className="flex items-baseline gap-1">
            <span className="text-[20px] font-bold text-slate-900">{Math.max(0, 1791 - calories)}</span>
            <span className="text-[12px] text-slate-400">千卡</span>
          </div>
        </div>
        <div className="bg-[#f2fcf9] p-3 rounded-[16px] text-center">
          <div className="text-[#36c79a] font-bold text-[18px]">{calories}</div>
          <div className="text-[12px] text-slate-400 mt-0.5">饮食</div>
        </div>
        <div className="bg-[#fff7f0] p-3 rounded-[16px] text-center">
          <div className="text-[#ff9d4d] font-bold text-[18px]">0</div>
          <div className="text-[12px] text-slate-400 mt-0.5">运动*0.9</div>
        </div>
      </div>

      <div className="flex justify-between items-center mb-6">
        {[
          { icon: Coffee, label: '早餐' },
          { icon: Pizza, label: '午餐' },
          { icon: Soup, label: '晚餐' },
          { icon: Apple, label: '加餐' },
          { icon: Footprints, label: '运动' },
        ].map((item, i) => (
          <div key={i} className="flex flex-col items-center gap-2 cursor-pointer active:scale-90 transition-transform" onClick={() => {
            if (item.label === '早餐') {
              onBreakfastClick();
            } else {
              toast.info(`正在记录${item.label}...`);
            }
          }}>
            <div className="w-12 h-12 rounded-full bg-slate-50 flex items-center justify-center border border-slate-100 shadow-sm">
              <item.icon className="w-6 h-6 text-slate-700" strokeWidth={1.5} />
            </div>
            <span className="text-[12px] text-slate-500 font-medium">{item.label}</span>
          </div>
        ))}
      </div>

      <button 
        onClick={onScan}
        className="w-full bg-[#f2fcf9] active:bg-[#dff9f1] transition-all py-3.5 rounded-full flex items-center justify-center gap-2 group cursor-pointer"
      >
        <Camera className="w-5 h-5 text-[#36c79a]" />
        <span className="text-[#36c79a] font-bold text-[15px]">智能饮食相机</span>
      </button>
    </div>
  );
};

interface RecordSectionProps {
  waterIcon: string;
  shoeIcon: string;
  water: number;
  steps: number;
  weight: number;
  weightUpdateTime: string;
  onAddWater: (amount: number) => void;
  onRemoveWater: (amount: number) => void;
  onAddSteps: () => void;
  onAddWeight: () => void;
  onAddExercise: () => void;
}

const RecordSection: React.FC<RecordSectionProps> = ({ 
  waterIcon, shoeIcon, water, steps, weight, weightUpdateTime, onAddWater, onRemoveWater, onAddSteps, onAddWeight, onAddExercise 
}) => {
  const [waterStep, setWaterStep] = useState(250);

  return (
    <div className="flex flex-col gap-6 mb-24">
      <div className="bg-white rounded-[24px] p-6 shadow-sm">
        <div className="flex items-center justify-between mb-4">
          <div>
            <span className="text-[17px] font-bold text-slate-800 block">体重记录</span>
            <span className="text-[12px] text-slate-400">{weightUpdateTime} 更新</span>
          </div>
          <button 
            className="w-10 h-10 rounded-full bg-[#f2fcf9] text-[#36c79a] flex items-center justify-center active:scale-95 hover:bg-[#e8fbf4] transition-all cursor-pointer shadow-sm shadow-[#36c79a]/10" 
            onClick={onAddWeight}
          >
            <Plus className="w-6 h-6" />
          </button>
        </div>
        <div className="flex items-baseline gap-2 mb-4">
          <motion.span 
            key={weight}
            initial={{ scale: 1.1, opacity: 0.5 }}
            animate={{ scale: 1, opacity: 1 }}
            className="text-[28px] font-bold text-slate-900"
          >
            {weight.toFixed(2)}
          </motion.span>
          <span className="text-[14px] text-slate-400 font-medium">公斤</span>
        </div>
        <div className="flex gap-1.5 justify-end">
          {[...Array(8)].map((_, i) => (
            <div key={i} className={`w-2 h-2 rounded-full ${i === 0 ? 'bg-[#36c79a]' : 'bg-slate-100'}`}></div>
          ))}
        </div>
      </div>

      <div className="bg-white rounded-[24px] p-6 shadow-sm">
        <div className="flex items-center justify-between mb-6">
          <span className="text-[17px] font-bold text-slate-800">运动记录</span>
          <button 
            className="w-10 h-10 rounded-full bg-[#f2fcf9] text-[#36c79a] flex items-center justify-center hover:bg-[#e8fbf4] transition-colors cursor-pointer" 
            onClick={onAddExercise}
          >
            <Plus className="w-6 h-6" />
          </button>
        </div>
        <div className="flex gap-12 mb-6">
          <div>
            <span className="text-[12px] text-slate-400 block mb-1">本周达成</span>
            <div className="flex items-baseline gap-1">
              <span className="text-[20px] font-bold text-slate-900">{steps > 0 ? 1 : '--'}</span>
              <span className="text-[12px] text-slate-400">天</span>
            </div>
          </div>
          <div>
            <span className="text-[12px] text-slate-400 block mb-1">每日平均</span>
            <div className="flex items-baseline gap-1">
              <span className="text-[20px] font-bold text-slate-900">{steps > 0 ? (steps * 0.04).toFixed(0) : '--'}</span>
              <span className="text-[12px] text-slate-400">kcal</span>
            </div>
          </div>
        </div>
        <div className="flex items-end justify-between h-16 gap-2">
          {[...Array(7)].map((_, i) => (
            <div key={i} className="flex flex-col items-center gap-1 w-full h-full">
              <div className="w-1.5 h-full bg-slate-50 rounded-full overflow-hidden relative">
                <div 
                  className="absolute bottom-0 left-0 w-full bg-[#36c79a] transition-all duration-1000" 
                  style={{ height: i === 6 ? `${Math.min(steps / 100, 100)}%` : '0%' }}
                ></div>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white rounded-[24px] p-6 shadow-sm relative overflow-hidden group">
          <div className="flex items-center justify-between mb-4 relative z-10">
            <span className="text-[17px] font-bold text-slate-800">喝水</span>
            <div className="flex items-center gap-1.5 bg-slate-50/80 p-1 rounded-full border border-slate-100/50">
              <button 
                onClick={() => onRemoveWater(waterStep)}
                className="w-7 h-7 rounded-full bg-white text-slate-400 flex items-center justify-center hover:bg-slate-100 transition-colors cursor-pointer shadow-sm active:scale-90"
              >
                <Minus className="w-3.5 h-3.5" />
              </button>
              <input 
                type="number"
                value={waterStep}
                onChange={(e) => setWaterStep(Number(e.target.value))}
                className="w-12 text-center text-[13px] font-bold text-slate-700 bg-transparent outline-none [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
              />
              <button 
                onClick={() => onAddWater(waterStep)}
                className="w-7 h-7 rounded-full bg-[#36c79a] text-white flex items-center justify-center hover:bg-[#2fb189] transition-colors cursor-pointer shadow-sm active:scale-90"
              >
                <Plus className="w-4 h-4" />
              </button>
            </div>
          </div>
          <div className="flex items-baseline gap-1 mb-2">
            <span className="text-[24px] font-bold text-slate-900">{water}</span>
            <span className="text-[12px] text-slate-400 font-medium">毫升</span>
          </div>
          <div className="absolute -right-2 -bottom-2 w-20 h-24 opacity-80 group-active:scale-110 transition-transform">
            <ImageWithFallback src={waterIcon} className="w-full h-full object-contain" />
          </div>
        </div>

        <div className="bg-white rounded-[24px] p-6 shadow-sm relative overflow-hidden group cursor-pointer" onClick={onAddSteps}>
          <div className="flex items-center justify-between mb-8">
            <span className="text-[17px] font-bold text-slate-800">步数</span>
          </div>
          <div className="flex items-baseline gap-1 mb-2">
            <span className="text-[24px] font-bold text-slate-900">{steps === 0 ? '--' : steps}</span>
            <span className="text-[12px] text-slate-400 font-medium">步</span>
          </div>
          <div className="absolute -right-2 -bottom-2 w-20 h-24 opacity-80 group-active:scale-110 transition-transform">
            <ImageWithFallback src={shoeIcon} className="w-full h-full object-contain rotate-[-15deg]" />
          </div>
        </div>
      </div>
    </div>
  );
};

// --- Main Page ---

const AVATAR_URL = "https://images.unsplash.com/photo-1639120653716-a53f88afeccc?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxmZW1hbGUlMjBwcm9maWxlJTIwYXZhdGFyJTIwM2QlMjByZW5kZXJ8ZW58MXx8fHwxNzc0MjQ5NzIzfDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral";
const WATER_ICON = "https://images.unsplash.com/photo-1628847355639-fa98190efc79?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxnbGFzcyUyMG9mJTIwd2F0ZXIlMjBibHVlJTIwM2QlMjBpY29ufGVufDF8fHx8MTc3NDI0OTcyM3ww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral";
const SHOE_ICON = "https://images.unsplash.com/photo-1518002171953-a080ee817e1f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxydW5uaW5nJTIwc2hvZSUyMHNuZWFrZXIlMjAzZCUyMGljb258ZW58MXx8fHwxNzc0MjQ5NzI0fDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral";

export default function Home() {
  const [water, setWater] = useState(0);
  const [steps, setSteps] = useState(0);
  const [calories, setCalories] = useState(0);
  const [weight, setWeight] = useState(62.00);
  const [weightUpdateTime, setWeightUpdateTime] = useState("14:59");
  const [isScanning, setIsScanning] = useState(false);
  const [isRecordingWeight, setIsRecordingWeight] = useState(false);
  const [isRecordingExercise, setIsRecordingExercise] = useState(false);
  const [isQuickRecording, setIsQuickRecording] = useState(false);
  const [isCalendarOpen, setIsCalendarOpen] = useState(false);
  const [quickRecordTitle, setQuickRecordTitle] = useState("设置快捷记录");
  const [checkedDates, setCheckedDates] = useState<Date[]>([]);
  const [checkedToday, setCheckedToday] = useState(false);

  const handleCheckIn = () => {
    if (!checkedToday) {
      const today = new Date();
      setCheckedDates(prev => [...prev, today]);
      setCheckedToday(true);
      toast.success("签到成功！", {
        description: "已加入今日打卡记录",
        icon: "🏆"
      });
    }
  };

  const handleAddWater = (amount: number) => {
    const val = amount || 250;
    setWater(prev => prev + val);
    toast.success(`加水 ${val}ml`, {
      icon: "💧",
      description: "保持水分摄入有助于新陈代谢"
    });
  };

  const handleRemoveWater = (amount: number) => {
    const val = amount || 250;
    setWater(prev => Math.max(0, prev - val));
    toast.info(`已扣除 ${val}ml 喝水记录`, {
      icon: "↩️"
    });
  };

  const handleAddSteps = () => {
    setSteps(prev => prev + 500);
    toast.success("步数 +500", {
      icon: "👟"
    });
  };

  const handleScan = () => {
    setIsScanning(true);
    const toastId = toast.loading("正在智能识别食物...");

    setTimeout(() => {
      const foodList = ["牛油果沙拉", "全麦吐司", "黑咖啡", "鸡胸肉"];
      const randomFood = foodList[Math.floor(Math.random() * foodList.length)];
      const randomCal = Math.floor(Math.random() * 300) + 50;
      
      setCalories(prev => prev + randomCal);
      setIsScanning(false);
      toast.dismiss(toastId);
      toast.success(`识别成功：${randomFood}`, {
        description: `摄入热量：+${randomCal}千卡`
      });
    }, 2000);
  };

  const handleSendMessage = async (msg: string) => {
    const toastId = toast.loading("AI 正在思考中...");
    
    try {
      const response = await aiService.chat(msg);
      
      toast.dismiss(toastId);
      
      if (response.status === 'success') {
        toast.success("AI 助手的建议：", {
          description: response.message,
          icon: <BrainCircuit className="w-5 h-5 text-[#36c79a]" />,
          duration: 5000,
        });
      } else {
        toast.error("AI 助手暂时不可用");
      }
    } catch (error) {
      toast.dismiss(toastId);
      toast.error("发送失败，请检查网络");
    }
  };

  const handleQuickRecordSave = (data: { name: string; value: number; unit: string }) => {
    setCalories(prev => prev + (data.value * 0.5)); // 简单模拟热量
    setIsQuickRecording(false);
    toast.success(`记录成功：${data.name}`, {
      description: `${data.value}${data.unit} 已加入今日记录`
    });
  };

  return (
    <div className="min-h-screen bg-[#f8fafc] pb-32">
      {/* Scanning Overlay */}
      <AnimatePresence>
        {isScanning && (
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-[100] bg-black/40 flex flex-col items-center justify-center backdrop-blur-sm"
          >
            <div className="relative w-64 h-64 border-2 border-[#36c79a] rounded-3xl overflow-hidden shadow-[0_0_30px_rgba(54,199,154,0.5)]">
              <motion.div 
                animate={{ top: ["0%", "100%", "0%"] }}
                transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
                className="absolute left-0 w-full h-1 bg-[#36c79a]"
              ></motion.div>
              <div className="w-full h-full bg-gradient-to-b from-[#36c79a]/20 to-transparent"></div>
            </div>
            <div className="mt-8 flex items-center gap-3 bg-white px-6 py-3 rounded-full shadow-lg">
              <Loader2 className="w-5 h-5 text-[#36c79a] animate-spin" />
              <span className="text-[#36c79a] font-bold">AI 视觉识别中...</span>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <AnimatePresence>
        {isRecordingWeight && (
          <WeightInput 
            initialWeight={weight}
            onClose={() => setIsRecordingWeight(false)}
            onSave={(newWeight) => {
              const now = new Date();
              const hh = String(now.getHours()).padStart(2, '0');
              const mm = String(now.getMinutes()).padStart(2, '0');
              setWeight(newWeight);
              setWeightUpdateTime(`${hh}:${mm}`);
              setIsRecordingWeight(false);
            }}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {isRecordingExercise && (
          <ExerciseRecord 
            onClose={() => setIsRecordingExercise(false)}
            onSave={(exercise) => {
              setSteps(prev => prev + (exercise.calories * 10)); // 简单模拟
              setIsRecordingExercise(false);
              toast.success(`已记录: ${exercise.name}`, {
                description: `消耗热量: ${exercise.calories} 千卡`
              });
            }}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {isQuickRecording && (
          <QuickRecord 
            title={quickRecordTitle}
            onClose={() => setIsQuickRecording(false)}
            onSave={handleQuickRecordSave}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {isCalendarOpen && (
          <CheckInCalendar 
            onClose={() => setIsCalendarOpen(false)}
            checkedDates={checkedDates}
            onCheckIn={handleCheckIn}
          />
        )}
      </AnimatePresence>

      <div className="px-4 pt-4">
        <Header 
          avatarUrl={AVATAR_URL} 
          onSendMessage={handleSendMessage} 
        />
        
        <CheckInCard 
          checked={checkedToday}
          onCheckIn={handleCheckIn}
          onOpenDetails={() => setIsCalendarOpen(true)}
        />
        
        <WeightPlanCard />
        
        <CalorieCard 
          calories={calories} 
          onScan={handleScan} 
          onBreakfastClick={() => {
            setQuickRecordTitle("早餐记录");
            setIsQuickRecording(true);
          }} 
        />
        
        <RecordSection 
          waterIcon={WATER_ICON} 
          shoeIcon={SHOE_ICON} 
          water={water}
          steps={steps}
          weight={weight}
          weightUpdateTime={weightUpdateTime}
          onAddWater={handleAddWater}
          onRemoveWater={handleRemoveWater}
          onAddSteps={handleAddSteps}
          onAddWeight={() => setIsRecordingWeight(true)}
          onAddExercise={() => setIsRecordingExercise(true)}
        />
      </div>
    </div>
  );
}
