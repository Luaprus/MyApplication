import React, { useState } from 'react';
import { motion } from 'motion/react';
import { X, Calendar as CalendarIcon, Trophy, Flame, ChevronLeft, ChevronRight } from 'lucide-react';
import { format, startOfMonth, endOfMonth, eachDayOfInterval, isSameDay, isToday, addMonths, subMonths, isAfter } from 'date-fns';
import { zhCN } from 'date-fns/locale';

interface CheckInCalendarProps {
  onClose: () => void;
  checkedDates: Date[];
  onCheckIn?: () => void;
}

export const CheckInCalendar: React.FC<CheckInCalendarProps> = ({ onClose, checkedDates, onCheckIn }) => {
  const [currentMonth, setCurrentMonth] = useState(new Date());
  
  // Check if today is already checked
  const isTodayChecked = checkedDates.some(d => isSameDay(d, new Date()));
  const [hasCheckedInToday, setHasCheckedInToday] = useState(isTodayChecked);

  const handleCheckIn = () => {
    if (!hasCheckedInToday) {
      setHasCheckedInToday(true);
      onCheckIn?.();
    }
  };

  const daysInMonth = eachDayOfInterval({
    start: startOfMonth(currentMonth),
    end: endOfMonth(currentMonth),
  });

  // Calculate stats
  // Use a local total that accounts for the new check-in
  const totalCheckedCount = checkedDates.length + (hasCheckedInToday && !isTodayChecked ? 1 : 0);
  const currentStreak = 1 + (hasCheckedInToday && !isTodayChecked ? 1 : 0); // Simplified logic

  const nextMonth = () => setCurrentMonth(addMonths(currentMonth, 1));
  const prevMonth = () => setCurrentMonth(subMonths(currentMonth, 1));

  const isChecked = (date: Date) => checkedDates.some(d => isSameDay(d, date));

  return (
    <motion.div
      initial={{ y: "100%" }}
      animate={{ y: 0 }}
      exit={{ y: "100%" }}
      transition={{ type: "spring", damping: 25, stiffness: 200 }}
      className="fixed inset-0 z-[110] bg-[#f8fafc] flex flex-col"
    >
      {/* Header */}
      <div className="flex items-center justify-between p-4 bg-white border-b border-slate-100">
        <button onClick={onClose} className="p-2 -ml-2 text-slate-400">
          <ChevronLeft className="w-6 h-6" />
        </button>
        <h2 className="text-[17px] font-bold text-slate-800">打卡详情</h2>
        <div className="w-10" /> {/* Spacer */}
      </div>

      <div className="flex-1 overflow-y-auto p-4 pb-12">
        {/* Stats Section */}
        <div className="grid grid-cols-2 gap-4 mb-6">
          <div className="bg-gradient-to-br from-[#36c79a] to-[#8ef6d8] p-5 rounded-[24px] text-white shadow-lg shadow-emerald-100/50">
            <div className="flex items-center gap-2 mb-2">
              <Trophy className="w-4 h-4 opacity-80" />
              <span className="text-[12px] opacity-90 font-medium">累计打卡</span>
            </div>
            <div className="flex items-baseline gap-1">
              <span className="text-[32px] font-bold">{totalCheckedCount}</span>
              <span className="text-[14px] font-medium opacity-80">天</span>
            </div>
          </div>
          <div className="bg-white p-5 rounded-[24px] border border-slate-100 shadow-sm">
            <div className="flex items-center gap-2 mb-2 text-orange-400">
              <Flame className="w-4 h-4" />
              <span className="text-[12px] text-slate-400 font-medium">连续打卡</span>
            </div>
            <div className="flex items-baseline gap-1">
              <span className="text-[32px] font-bold text-slate-900">{currentStreak}</span>
              <span className="text-[14px] font-medium text-slate-400">天</span>
            </div>
          </div>
        </div>

        {/* Calendar Card */}
        <div className="bg-white rounded-[28px] p-6 shadow-sm border border-slate-50">
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-2">
              <CalendarIcon className="w-5 h-5 text-emerald-400" />
              <span className="font-bold text-slate-800 text-[17px]">
                {format(currentMonth, 'yyyy年MM月', { locale: zhCN })}
              </span>
            </div>
            <div className="flex gap-4">
              <button onClick={prevMonth} className="p-1.5 rounded-full hover:bg-slate-50 transition-colors">
                <ChevronLeft className="w-5 h-5 text-slate-400" />
              </button>
              <button onClick={nextMonth} className="p-1.5 rounded-full hover:bg-slate-50 transition-colors">
                <ChevronRight className="w-5 h-5 text-slate-400" />
              </button>
            </div>
          </div>

          <div className="grid grid-cols-7 mb-4">
            {['日', '一', '二', '三', '四', '五', '六'].map((day) => (
              <div key={day} className="text-center text-[12px] text-slate-400 font-medium py-2">
                {day}
              </div>
            ))}
          </div>

          <div className="grid grid-cols-7 gap-y-3">
            {/* Pad the start of the month */}
            {Array.from({ length: startOfMonth(currentMonth).getDay() }).map((_, i) => (
              <div key={`pad-${i}`} />
            ))}
            
            {daysInMonth.map((day) => {
              const checked = isChecked(day);
              const today = isToday(day);
              const future = isAfter(day, new Date()) && !today;

              return (
                <div key={day.toString()} className="relative flex items-center justify-center p-1">
                  <div 
                    className={`
                      w-10 h-10 rounded-2xl flex items-center justify-center text-[14px] font-bold transition-all
                      ${checked ? 'bg-[#36c79a] text-white shadow-md shadow-emerald-100 scale-110' : ''}
                      ${!checked && today ? 'border-2 border-emerald-100 text-[#36c79a]' : ''}
                      ${!checked && !today ? 'text-slate-700' : ''}
                      ${future ? 'opacity-30' : ''}
                    `}
                  >
                    {format(day, 'd')}
                    {checked && (
                      <motion.div 
                        initial={{ scale: 0 }}
                        animate={{ scale: 1 }}
                        className="absolute -top-1 -right-1 w-3.5 h-3.5 bg-yellow-400 rounded-full border-2 border-white flex items-center justify-center"
                      >
                        <div className="w-1.5 h-1.5 bg-white rounded-full" />
                      </motion.div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Motivation Card */}
        <div className="mt-6 bg-[#f2fcf9] p-5 rounded-[24px] border border-emerald-50 mb-20">
          <p className="text-[#36c79a] text-[14px] leading-relaxed font-medium">
            "每一个你坚持下来的日子，都是在为未来的自己写下最美的注脚。保持节奏，顶峰相见。"
          </p>
        </div>
      </div>

      {/* Persistent Button */}
      <div className="p-4 bg-white border-t border-slate-100 pb-8">
        <button
          onClick={handleCheckIn}
          disabled={hasCheckedInToday}
          className={`
            w-full h-14 rounded-2xl flex items-center justify-center gap-2 font-bold text-[16px] transition-all
            ${hasCheckedInToday 
              ? 'bg-slate-100 text-slate-400' 
              : 'bg-gradient-to-r from-[#36c79a] to-[#8ef6d8] text-white shadow-lg shadow-emerald-100'
            }
          `}
        >
          {hasCheckedInToday ? (
            <>
              <Trophy className="w-5 h-5 opacity-50" />
              今日已打卡
            </>
          ) : (
            <>
              <Flame className="w-5 h-5" />
              立即打卡
            </>
          )}
        </button>
      </div>
    </motion.div>
  );
};
