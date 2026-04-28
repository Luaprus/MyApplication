import React, { useRef, useEffect, useState } from 'react';
import { motion } from 'motion/react';

interface WeightRulerProps {
  value: number;
  onChange: (value: number) => void;
  min?: number;
  max?: number;
  step?: number;
}

export const WeightRuler: React.FC<WeightRulerProps> = ({
  value,
  onChange,
  min = 30,
  max = 150,
  step = 0.1
}) => {
  const scrollRef = useRef<HTMLDivElement>(null);
  const [isScrolling, setIsScrolling] = useState(false);
  
  // 每 0.1kg 对应的像素宽度
  const pixelsPerStep = 10;
  // 尺子左侧留白，使刻度对齐中心
  const [padding, setPadding] = useState(0);

  useEffect(() => {
    if (scrollRef.current) {
      const containerWidth = scrollRef.current.offsetWidth;
      const centerOffset = containerWidth / 2;
      setPadding(centerOffset);
      
      // 初始滚动到当前值
      const scrollPosition = (value - min) / step * pixelsPerStep;
      scrollRef.current.scrollLeft = scrollPosition;
    }
  }, []);

  const handleScroll = () => {
    if (!scrollRef.current) return;
    
    const scrollLeft = scrollRef.current.scrollLeft;
    const newValue = min + (scrollLeft / pixelsPerStep) * step;
    
    // 限制范围并保留两位小数
    const clampedValue = Math.min(Math.max(newValue, min), max);
    onChange(Number(clampedValue.toFixed(2)));
  };

  const onScrollStart = () => setIsScrolling(true);
  const onScrollEnd = () => setIsScrolling(false);

  // 生成刻度线
  const stepsCount = (max - min) / step;
  const marks = [];
  for (let i = 0; i <= stepsCount; i++) {
    const currentWeight = min + i * step;
    const isMajor = i % 10 === 0; // 整数
    const isMedium = i % 5 === 0 && !isMajor; // 0.5
    
    marks.push(
      <div 
        key={i} 
        className="flex flex-col items-center shrink-0" 
        style={{ width: `${pixelsPerStep}px` }}
      >
        <div 
          className={`w-[1px] rounded-full transition-all duration-300 ${
            isMajor ? 'h-8 bg-[#36c79a]' : 
            isMedium ? 'h-5 bg-[#36c79a]/60' : 
            'h-3 bg-[#36c79a]/30'
          }`}
        />
        {isMajor && (
          <span className="mt-2 text-[10px] font-bold text-slate-400 select-none">
            {currentWeight.toFixed(0)}
          </span>
        )}
      </div>
    );
  }

  return (
    <div className="relative w-full h-24 mt-4 overflow-hidden">
      {/* 渐变遮罩 */}
      <div className="absolute inset-y-0 left-0 w-16 bg-gradient-to-r from-white to-transparent z-10 pointer-events-none" />
      <div className="absolute inset-y-0 right-0 w-16 bg-gradient-to-l from-white to-transparent z-10 pointer-events-none" />
      
      {/* 中心指示器 */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 z-20 pointer-events-none flex flex-col items-center">
        <div className="w-[3px] h-10 bg-[#36c79a] rounded-full shadow-[0_0_8px_rgba(54,199,154,0.4)]" />
        <motion.div 
          animate={{ scale: isScrolling ? 1.2 : 1 }}
          className="w-2 h-2 rounded-full bg-[#36c79a] mt-1"
        />
      </div>

      {/* 滚动尺 */}
      <div 
        ref={scrollRef}
        onScroll={handleScroll}
        onScrollCapture={onScrollStart}
        onTransitionEnd={onScrollEnd}
        onTouchStart={onScrollStart}
        onTouchEnd={onScrollEnd}
        className="w-full h-full overflow-x-auto no-scrollbar touch-pan-x"
        style={{ scrollBehavior: 'auto' }}
      >
        <div 
          className="flex items-start h-full"
          style={{ 
            paddingLeft: `${padding}px`, 
            paddingRight: `${padding}px`,
            width: 'max-content'
          }}
        >
          {marks}
        </div>
      </div>
    </div>
  );
};
