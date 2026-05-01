export interface DailyCompletionItem {
  id: string;
  title: string;
  valueText: string;
  completed: boolean;
  tint: string;
  bgColor: string;
}

export interface DailyCompletionSummary {
  percent: number;
  completedCount: number;
  totalCount: number;
  headline: string;
  actionText: string;
  items: DailyCompletionItem[];
}

export function buildDailyCompletionSummary(recordedMealTypeCount: number, water: number, waterGoal: number,
  exerciseCalories: number, hasWeightToday: boolean): DailyCompletionSummary {
  let items: DailyCompletionItem[] = [
    {
      id: 'meal',
      title: '\u9910\u98df',
      valueText: `${Math.min(3, recordedMealTypeCount)}/3`,
      completed: recordedMealTypeCount >= 3,
      tint: '#FF9D4D',
      bgColor: '#FFF7EE'
    },
    {
      id: 'water',
      title: '\u996e\u6c34',
      valueText: waterGoal > 0 ? `${Math.min(100, Math.round((water / waterGoal) * 100))}%` : '0%',
      completed: waterGoal > 0 && water >= waterGoal,
      tint: '#32C5F4',
      bgColor: '#E9F9FF'
    },
    {
      id: 'exercise',
      title: '\u8fd0\u52a8',
      valueText: `${exerciseCalories}kcal`,
      completed: exerciseCalories >= 180,
      tint: '#36C79A',
      bgColor: '#ECFBF5'
    },
    {
      id: 'weight',
      title: '\u4f53\u91cd',
      valueText: hasWeightToday ? '\u5df2\u8bb0' : '\u672a\u8bb0',
      completed: hasWeightToday,
      tint: '#4B8DFF',
      bgColor: '#EEF4FF'
    }
  ];

  let completedCount: number = 0;
  for (let index = 0; index < items.length; index++) {
    if (items[index].completed) {
      completedCount += 1;
    }
  }

  return {
    percent: Math.round((completedCount / items.length) * 100),
    completedCount: completedCount,
    totalCount: items.length,
    headline: dailyCompletionHeadline(completedCount, items.length),
    actionText: nextCompletionAction(items),
    items: items
  };
}

function dailyCompletionHeadline(completedCount: number, totalCount: number): string {
  if (completedCount >= totalCount) {
    return '\u4eca\u5929\u56db\u9879\u5173\u952e\u8bb0\u5f55\u90fd\u5b8c\u6210\u4e86';
  }
  if (completedCount >= 2) {
    return '\u4eca\u5929\u8282\u594f\u4e0d\u9519\uff0c\u518d\u8865\u4e00\u4e24\u9879\u5c31\u66f4\u7a33';
  }
  return '\u5148\u6293\u4f4f\u4e00\u9879\u5c0f\u8bb0\u5f55\uff0c\u4eca\u5929\u5c31\u80fd\u5f00\u59cb\u8fde\u4e0a';
}

function nextCompletionAction(items: DailyCompletionItem[]): string {
  for (let index = 0; index < items.length; index++) {
    if (!items[index].completed) {
      if (items[index].id === 'meal') {
        return '\u5148\u8865\u5168\u4e09\u9910\u8bb0\u5f55';
      }
      if (items[index].id === 'water') {
        return '\u518d\u8865\u4e00\u676f\u6c34';
      }
      if (items[index].id === 'exercise') {
        return '\u5b89\u6392\u4e00\u6b21\u8f7b\u8fd0\u52a8';
      }
      return '\u8bb0\u5f55\u4eca\u5929\u4f53\u91cd';
    }
  }
  return '\u53bb\u770b AI \u5468\u62a5';
}
