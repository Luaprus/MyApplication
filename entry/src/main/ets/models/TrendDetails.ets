import { ExerciseRecordItem, MealRecordItem, WaterRecordItem, WeightRecordItem } from './AppState';
import { mealLabel } from './MealDisplay';
import { latestWeightForDay } from './FeatureInsights';

export function countMealsForDay(records: MealRecordItem[], dayKey: string): number {
  let count: number = 0;
  for (let index = 0; index < records.length; index++) {
    if (records[index].dayKey === dayKey) {
      count += 1;
    }
  }
  return count;
}

export function countWaterRecordsForDay(records: WaterRecordItem[], dayKey: string): number {
  let count: number = 0;
  for (let index = 0; index < records.length; index++) {
    if (records[index].dayKey === dayKey) {
      count += 1;
    }
  }
  return count;
}

export function weightTextForDay(records: WeightRecordItem[], dayKey: string): string {
  let latestWeight: number = latestWeightForDay(records, dayKey);
  return latestWeight > 0 ? `${latestWeight.toFixed(1)}kg` : '--';
}

export function trendDayDetailText(mealCount: number, waterCount: number, weightText: string): string {
  if (mealCount === 0 && waterCount === 0 && weightText === '--') {
    return '\u8fd9\u4e00\u5929\u8fd8\u6ca1\u6709\u8bb0\u5f55\uff0c\u540e\u7eed\u8865\u5f55\u540e\u4f1a\u51fa\u73b0\u5728\u8fd9\u91cc\u3002';
  }
  return `\u9910\u98df ${mealCount} \u6761\uff0c\u996e\u6c34 ${waterCount} \u6761\uff0c\u4f53\u91cd ${weightText}\u3002`;
}

export function dayRecordDetails(dayKey: string, meals: MealRecordItem[], waters: WaterRecordItem[],
  exercises: ExerciseRecordItem[], weights: WeightRecordItem[]): string[] {
  let lines: string[] = [];
  for (let index = 0; index < meals.length; index++) {
    let item: MealRecordItem = meals[index];
    if (item.dayKey === dayKey) {
      lines.push(`${mealLabel(item.mealType)} \u00b7 ${item.time} \u00b7 ${item.name} ${item.calories}kcal`);
    }
  }
  for (let index = 0; index < waters.length; index++) {
    let item: WaterRecordItem = waters[index];
    if (item.dayKey === dayKey) {
      lines.push(`\u996e\u6c34 \u00b7 ${item.time} \u00b7 ${item.drinkName} ${item.amount}ml`);
    }
  }
  for (let index = 0; index < exercises.length; index++) {
    let item: ExerciseRecordItem = exercises[index];
    if (item.dayKey === dayKey) {
      lines.push(`\u8fd0\u52a8 \u00b7 ${item.time} \u00b7 ${item.name} ${item.duration}\u5206\u949f ${item.calories}kcal`);
    }
  }
  for (let index = 0; index < weights.length; index++) {
    let item: WeightRecordItem = weights[index];
    if (item.dayKey === dayKey) {
      lines.push(`\u4f53\u91cd \u00b7 ${item.time} \u00b7 ${item.value.toFixed(2)}kg`);
    }
  }
  return lines.slice(0, 8);
}
