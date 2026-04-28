import React, { useState, useEffect } from 'react';
import { ArrowLeft, Search, Check, Plus, Trash2, X } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { ImageWithFallback } from './figma/ImageWithFallback';
import { toast } from 'sonner';

interface ExerciseItem {
  id: string;
  name: string;
  calories: number;
  duration: number; // minutes
  icon: string;
}

interface ExerciseRecordProps {
  onClose: () => void;
  onSave: (exercise: any) => void;
}

const CATEGORIES = [
  "热门", "自定义", "..........", "步行", "跑步", "骑行", "球类", 
  "水上运动", "其它运动", "健身综合", "有氧器械", "舞蹈跳操", "武术传统", "柔韧拉伸"
];

const EXERCISES: Record<string, ExerciseItem[]> = {
  "热门": [
    { id: '1', name: '跑步机爬坡', calories: 673, duration: 60, icon: 'https://images.unsplash.com/photo-1597452485669-2c7bb5fef90d?w=100&h=100&fit=crop' },
    { id: '2', name: '原地超慢跑 (低强度)', calories: 291, duration: 60, icon: 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=100&h=100&fit=crop' },
    { id: '3', name: '原地超慢跑 (中强度)', calories: 415, duration: 60, icon: 'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?w=100&h=100&fit=crop' },
    { id: '4', name: '原地超慢跑 (高强度)', calories: 540, duration: 60, icon: 'https://images.unsplash.com/photo-1530604233934-71bc182ae614?w=100&h=100&fit=crop' },
    { id: '5', name: '呼啦圈', calories: 208, duration: 60, icon: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=100&h=100&fit=crop' },
    { id: '6', name: '慢速跳绳 (约 <100次/分钟)', calories: 648, duration: 60, icon: 'https://images.unsplash.com/photo-1517438476312-10d79c6775e3?w=100&h=100&fit=crop' },
    { id: '7', name: '中速跳绳 (约100-120次/分钟)', calories: 897, duration: 60, icon: 'https://images.unsplash.com/photo-1594911772125-07fc7a2d8d9f?w=100&h=100&fit=crop' },
    { id: '8', name: '快速跳绳 (约120-160次/分钟)', calories: 939, duration: 60, icon: 'https://images.unsplash.com/photo-1598136490941-30d885318abd?w=100&h=100&fit=crop' },
  ]
};

const AI_ICON = "https://images.unsplash.com/photo-1620712943543-bcc4628c6759?w=100&h=100&fit=crop";

export const ExerciseRecord: React.FC<ExerciseRecordProps> = ({ onClose, onSave }) => {
  const [activeCategory, setActiveCategory] = useState("热门");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedExercise, setSelectedExercise] = useState<string | null>(null);
  const [customExercises, setCustomExercises] = useState<ExerciseItem[]>([
    { id: 'c1', name: '晨起拉伸', calories: 120, duration: 30, icon: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=100&h=100&fit=crop' },
    { id: 'c2', name: '快步走', calories: 250, duration: 45, icon: 'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?w=100&h=100&fit=crop' }
  ]);
  const [showAddForm, setShowAddForm] = useState(false);
  const [newExName, setNewExName] = useState("");
  const [newExCal, setNewExCal] = useState("");

  const filteredExercises = EXERCISES["热门"].filter(ex => 
    ex.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const filteredCustom = customExercises.filter(ex => 
    ex.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const handleAddCustom = () => {
    if (!newExName.trim() || !newExCal) {
      toast.error("请输入完整的名称和热量");
      return;
    }
    const newEx: ExerciseItem = {
      id: Date.now().toString(),
      name: newExName,
      calories: parseInt(newExCal),
      duration: 60,
      icon: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=100&h=100&fit=crop'
    };
    setCustomExercises(prev => [...prev, newEx]);
    setNewExName("");
    setNewExCal("");
    setShowAddForm(false);
    toast.success(`已添加自定义运动：${newExName}`);
  };

  const handleDeleteCustom = (e: React.MouseEvent, id: string) => {
    e.stopPropagation();
    setCustomExercises(prev => prev.filter(ex => ex.id !== id));
    if (selectedExercise === id) setSelectedExercise(null);
    toast.info("已删除该自定义运动");
  };

  const displayExercises = activeCategory === "热门" ? filteredExercises : (activeCategory === "自定义" ? filteredCustom : []);

  return (
    <motion.div 
      initial={{ y: '100%' }}
      animate={{ y: 0 }}
      exit={{ y: '100%' }}
      transition={{ type: 'spring', damping: 25, stiffness: 200 }}
      className="fixed inset-0 z-[120] bg-white flex flex-col"
    >
      {/* Header */}
      <div className="flex items-center gap-4 px-4 py-3 border-b border-slate-50">
        <button onClick={onClose} className="p-1 -ml-1">
          <ArrowLeft className="w-6 h-6 text-slate-700" />
        </button>
        <h1 className="text-lg font-bold text-slate-800">2026/03/30 运动</h1>
      </div>

      {/* Search */}
      <div className="px-4 py-3">
        <div className="relative">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
          <input 
            type="text" 
            placeholder="请输入运动名称"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-slate-50 rounded-full py-2.5 pl-11 pr-4 text-[15px] outline-none border-none placeholder:text-slate-400"
          />
        </div>
      </div>

      <div className="flex-1 flex overflow-hidden">
        {/* Sidebar */}
        <div className="w-[100px] bg-slate-50/50 overflow-y-auto no-scrollbar py-2">
          {CATEGORIES.map((cat, idx) => {
            if (cat === "..........") {
              return (
                <div key={idx} className="px-4 py-6 flex items-center justify-center">
                  <div className="w-full h-[2px] bg-slate-200 rounded-full" />
                </div>
              );
            }
            return (
              <button
                key={idx}
                onClick={() => setActiveCategory(cat)}
                className={`w-full py-4 px-2 text-[15px] transition-all relative ${
                  activeCategory === cat 
                    ? 'bg-white text-slate-900 font-bold' 
                    : 'text-slate-400 font-medium'
                }`}
              >
                {activeCategory === cat && (
                  <div className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-5 bg-emerald-400 rounded-r-full" />
                )}
                {cat}
              </button>
            );
          })}
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-4 pt-2">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <div className="w-1.5 h-4 bg-emerald-200 rounded-full" />
              <h2 className="text-[17px] font-bold text-slate-800">{activeCategory}</h2>
            </div>
            {activeCategory === "自定义" && (
              <button 
                onClick={() => setShowAddForm(true)}
                className="w-8 h-8 rounded-full bg-emerald-50 text-emerald-500 flex items-center justify-center active:scale-90 transition-transform"
              >
                <Plus className="w-5 h-5" />
              </button>
            )}
          </div>

          <div className="space-y-4 pb-24">
            <AnimatePresence mode="popLayout">
              {displayExercises.map((ex) => (
                <motion.div 
                  key={ex.id}
                  layout
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, scale: 0.95 }}
                  onClick={() => setSelectedExercise(ex.id === selectedExercise ? null : ex.id)}
                  className={`flex items-center gap-4 p-1 rounded-2xl transition-all active:scale-[0.98] ${
                    selectedExercise === ex.id ? 'bg-emerald-50/50 ring-1 ring-emerald-100' : ''
                  }`}
                >
                  <div className="w-16 h-16 rounded-2xl bg-orange-100/60 flex items-center justify-center overflow-hidden shrink-0">
                    <ImageWithFallback 
                      src={ex.icon} 
                      className="w-full h-full object-cover" 
                    />
                  </div>
                  <div className="flex-1 border-b border-slate-50 pb-4 h-full flex flex-col justify-center relative">
                    <h3 className="text-[16px] font-bold text-slate-800 mb-1 leading-tight">{ex.name}</h3>
                    <div className="flex items-baseline gap-1">
                      <span className="text-[16px] font-bold text-rose-500">{ex.calories}</span>
                      <span className="text-[12px] text-slate-400 font-medium">千卡/{ex.duration}分钟</span>
                    </div>
                    {activeCategory === "自定义" && (
                      <button 
                        onClick={(e) => handleDeleteCustom(e, ex.id)}
                        className="absolute right-0 top-1/2 -translate-y-1/2 p-2 text-slate-300 hover:text-rose-400 active:scale-90 transition-all"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    )}
                  </div>
                </motion.div>
              ))}
            </AnimatePresence>
            
            {displayExercises.length === 0 && (
              <div className="flex flex-col items-center justify-center py-20 text-slate-300">
                <p className="text-sm">暂无数据</p>
                {activeCategory === "自定义" && (
                  <button 
                    onClick={() => setShowAddForm(true)}
                    className="mt-4 text-[14px] text-emerald-500 font-medium bg-emerald-50 px-6 py-2 rounded-full"
                  >
                    去添加自定义运动
                  </button>
                )}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Add Custom Modal */}
      <AnimatePresence>
        {showAddForm && (
          <div className="fixed inset-0 z-[200] flex items-center justify-center p-6 bg-black/20 backdrop-blur-[2px]">
            <motion.div 
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              className="w-full max-w-sm bg-white rounded-[32px] p-6 shadow-2xl"
            >
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-[18px] font-bold text-slate-800">新建自定义运动</h3>
                <button onClick={() => setShowAddForm(false)} className="p-2 -mr-2 text-slate-400">
                  <X className="w-5 h-5" />
                </button>
              </div>
              <div className="space-y-4 mb-8">
                <div>
                  <label className="text-[13px] text-slate-400 ml-2 mb-1 block">运动名称</label>
                  <input 
                    type="text"
                    value={newExName}
                    onChange={(e) => setNewExName(e.target.value)}
                    placeholder="如：早起帕梅拉"
                    className="w-full bg-slate-50 border-none outline-none rounded-2xl py-3.5 px-4 text-[15px] text-slate-800 placeholder:text-slate-300"
                  />
                </div>
                <div>
                  <label className="text-[13px] text-slate-400 ml-2 mb-1 block">每小时热量 (千卡)</label>
                  <input 
                    type="number"
                    value={newExCal}
                    onChange={(e) => setNewExCal(e.target.value)}
                    placeholder="如：350"
                    className="w-full bg-slate-50 border-none outline-none rounded-2xl py-3.5 px-4 text-[15px] text-slate-800 placeholder:text-slate-300"
                  />
                </div>
              </div>
              <button 
                onClick={handleAddCustom}
                className="w-full bg-[#00c677] text-white font-bold py-4 rounded-full text-[16px] active:scale-[0.98] transition-all shadow-lg shadow-emerald-100"
              >
                确定添加
              </button>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Footer */}
      <div className="p-4 px-6 pb-8 border-t border-slate-50 flex items-center gap-4 bg-white">
        <div className="w-12 h-12 rounded-full overflow-hidden shadow-sm bg-slate-50 shrink-0">
          <ImageWithFallback src={AI_ICON} className="w-full h-full object-cover opacity-60" />
        </div>
        <button 
          onClick={() => {
            if (selectedExercise) {
              const allEx = [...EXERCISES["热门"], ...customExercises];
              const ex = allEx.find(e => e.id === selectedExercise);
              onSave(ex);
            } else {
              onClose();
            }
          }}
          className="flex-1 bg-[#00c677] hover:bg-[#00b36b] active:scale-95 transition-all text-white font-bold py-3.5 rounded-full text-[17px] shadow-lg shadow-emerald-100"
        >
          完成
        </button>
      </div>
    </motion.div>
  );
};
