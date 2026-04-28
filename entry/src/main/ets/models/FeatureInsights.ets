import { ExerciseRecordItem, FavoriteFoodItem, MealRecordItem, WaterRecordItem, WeightRecordItem } from './AppState';

export interface TrendDaySummary {
  dayKey: string;
  label: string;
  calories: number;
  water: number;
  exerciseCalories: number;
  weightText: string;
  hasRecords: boolean;
}

export interface SmartReminder {
  title: string;
  message: string;
  tint: string;
  bgColor: string;
}

export interface GoalAdjustment {
  calorieText: string;
  exerciseText: string;
  paceText: string;
}

export interface AchievementSummary {
  points: number;
  lines: string[];
}

export function buildTrendDaySummaries(dayKeys: string[], meals: MealRecordItem[], waters: WaterRecordItem[],
  exercises: ExerciseRecordItem[], weights: WeightRecordItem[]): TrendDaySummary[] {
  let summaries: TrendDaySummary[] = [];
  for (let dayIndex = 0; dayIndex < dayKeys.length; dayIndex++) {
    let dayKey: string = dayKeys[dayIndex];
    let calories: number = mealCaloriesForDay(meals, dayKey);
    let water: number = waterAmountForDay(waters, dayKey);
    let exerciseCalories: number = exerciseCaloriesForDay(exercises, dayKey);
    let weight: number = weightForDay(weights, dayKey);
    summaries.push({
      dayKey: dayKey,
      label: dayKey.slice(5).replace('-', '/'),
      calories: calories,
      water: water,
      exerciseCalories: exerciseCalories,
      weightText: weight > 0 ? `${weight.toFixed(1)}kg` : '--',
      hasRecords: calories > 0 || water > 0 || exerciseCalories > 0 || weight > 0
    });
  }
  return summaries;
}

export function buildMonthCalendarDayKeys(anchorDayKey: string): string[] {
  let anchor: Date = dateFromDayKey(anchorDayKey);
  let firstDay: Date = new Date(anchor.getFullYear(), anchor.getMonth(), 1);
  let lastDay: Date = new Date(anchor.getFullYear(), anchor.getMonth() + 1, 0);
  let firstWeekDay: number = firstDay.getDay();
  let mondayOffset: number = firstWeekDay === 0 ? -6 : 1 - firstWeekDay;
  let startDay: Date = new Date(firstDay.getTime());
  startDay.setDate(firstDay.getDate() + mondayOffset);

  let lastWeekDay: number = lastDay.getDay();
  let sundayOffset: number = lastWeekDay === 0 ? 0 : 7 - lastWeekDay;
  let endDay: Date = new Date(lastDay.getTime());
  endDay.setDate(lastDay.getDate() + sundayOffset);

  let keys: string[] = [];
  let cursor: Date = new Date(startDay.getTime());
  while (cursor.getTime() <= endDay.getTime()) {
    keys.push(dayKeyFromDate(cursor));
    cursor.setDate(cursor.getDate() + 1);
  }
  return keys;
}

export function buildSmartReminders(water: number, waterGoal: number, dinnerCalories: number,
  daysSinceWeight: number, shouldCheckDinner: boolean): SmartReminder[] {
  let reminders: SmartReminder[] = [];
  if (waterGoal > 0 && water < waterGoal * 0.6) {
    reminders.push({
      title: '\u996e\u6c34\u8fdb\u5ea6\u504f\u4f4e',
      message: `\u4eca\u65e5\u8fd8\u5dee ${Math.max(0, waterGoal - water)}ml\uff0c\u53ef\u4ee5\u5148\u8865\u4e00\u676f 300ml\u3002`,
      tint: '#32C5F4',
      bgColor: '#E9F9FF'
    });
  }
  if (shouldCheckDinner && dinnerCalories <= 0) {
    reminders.push({
      title: '\u665a\u9910\u8fd8\u6ca1\u8bb0',
      message: '\u5982\u679c\u5df2\u7ecf\u5403\u8fc7\u665a\u9910\uff0c\u8bb0\u4e00\u4e0b\u53ef\u4ee5\u8ba9 AI \u5468\u62a5\u66f4\u51c6\u3002',
      tint: '#8B5CF6',
      bgColor: '#F4EEFF'
    });
  }
  if (daysSinceWeight >= 3) {
    reminders.push({
      title: '\u9700\u8981\u79f0\u4e00\u6b21\u4f53\u91cd',
      message: `\u5df2\u7ecf ${daysSinceWeight} \u5929\u6ca1\u6709\u65b0\u4f53\u91cd\uff0c\u8d8b\u52bf\u4f1a\u53d8\u5f97\u4e0d\u591f\u8fde\u7eed\u3002`,
      tint: '#F97316',
      bgColor: '#FFF3EA'
    });
  }
  if (reminders.length === 0) {
    reminders.push({
      title: '\u4eca\u5929\u8282\u594f\u7a33\u5b9a',
      message: '\u5173\u952e\u8bb0\u5f55\u90fd\u5728\u63a8\u8fdb\uff0c\u7ee7\u7eed\u4fdd\u6301\u8fd9\u4e2a\u9891\u7387\u3002',
      tint: '#36C79A',
      bgColor: '#ECFBF5'
    });
  }
  return reminders;
}

export function buildGoalAdjustment(calories: number, exerciseCalories: number, weekLoss: number,
  weeklyTarget: number): GoalAdjustment {
  let safeTarget: number = weeklyTarget > 0 ? weeklyTarget : 0.3;
  if (weekLoss < safeTarget * 0.5) {
    return {
      calorieText: `\u53ef\u4ee5\u518d\u5c11\u5403 150~200kcal\uff0c\u4eca\u65e5\u5df2\u8bb0 ${calories}kcal\u3002`,
      exerciseText: exerciseCalories < 180 ? '\u5efa\u8bae\u589e\u52a0 20 \u5206\u949f\u5feb\u8d70\u6216\u529b\u91cf\u8bad\u7ec3\u3002' : '\u8fd0\u52a8\u91cf\u5df2\u7ecf\u4e0d\u9519\uff0c\u5148\u7a33\u4f4f\u996e\u98df\u3002',
      paceText: '\u8fdb\u5ea6\u7565\u6162'
    };
  }
  if (weekLoss > safeTarget * 1.6) {
    return {
      calorieText: '\u4eca\u5929\u53ef\u4ee5\u591a\u7559 150kcal \u7ed9\u86cb\u767d\u8d28\u548c\u852c\u83dc\u3002',
      exerciseText: '\u4e0b\u4e00\u6b21\u8fd0\u52a8\u4ee5\u6062\u590d\u548c\u62c9\u4f38\u4e3a\u4e3b\uff0c\u522b\u628a\u8282\u594f\u62c9\u592a\u731b\u3002',
      paceText: '\u8fdb\u5ea6\u504f\u5feb'
    };
  }
  return {
    calorieText: `\u4eca\u65e5\u8fd8\u53ef\u56f4\u7ed5 ${Math.max(0, 1800 - calories)}kcal \u7075\u6d3b\u5b89\u6392\u3002`,
    exerciseText: exerciseCalories >= 200 ? '\u8fd0\u52a8\u6d88\u8017\u8fbe\u6807\uff0c\u665a\u4e0a\u4f18\u5148\u7761\u7720\u548c\u6062\u590d\u3002' : '\u8865\u4e00\u6b21 15~20 \u5206\u949f\u8f7b\u8fd0\u52a8\u5c31\u591f\u3002',
    paceText: '\u8282\u594f\u6b63\u5e38'
  };
}

export function buildAchievementSummary(streakDays: number, water: number, waterGoal: number,
  exerciseCalories: number, recordedMealCount: number): AchievementSummary {
  let points: number = 0;
  let lines: string[] = [];
  if (streakDays > 0) {
    let streakPoints: number = Math.min(20, streakDays * 2);
    points += streakPoints;
    lines.push(`\u8fde\u7eed\u6253\u5361 +${streakPoints}`);
  }
  if (waterGoal > 0 && water >= waterGoal) {
    points += 10;
    lines.push('\u996e\u6c34\u8fbe\u6807 +10');
  }
  if (exerciseCalories >= 200) {
    points += 12;
    lines.push('\u5b8c\u6210\u8fd0\u52a8 +12');
  }
  if (recordedMealCount >= 3) {
    points += 9;
    lines.push('\u4e09\u9910\u8bb0\u5f55 +9');
  }
  return {
    points: points,
    lines: lines
  };
}

export function buildHealthDataCsv(meals: MealRecordItem[], waters: WaterRecordItem[],
  weights: WeightRecordItem[], exercises: ExerciseRecordItem[]): string {
  let lines: string[] = ['type,day,time,name,value,unit'];
  for (let mealIndex = 0; mealIndex < meals.length; mealIndex++) {
    let item: MealRecordItem = meals[mealIndex];
    lines.push(`meal,${item.dayKey},${item.time},${sanitizeCsvCell(item.name)},${item.calories},kcal`);
  }
  for (let waterIndex = 0; waterIndex < waters.length; waterIndex++) {
    let item: WaterRecordItem = waters[waterIndex];
    lines.push(`water,${item.dayKey},${item.time},${sanitizeCsvCell(item.drinkName)},${item.amount},ml`);
  }
  for (let weightIndex = 0; weightIndex < weights.length; weightIndex++) {
    let item: WeightRecordItem = weights[weightIndex];
    lines.push(`weight,${item.dayKey},${item.time},\u4f53\u91cd,${item.value},kg`);
  }
  for (let exerciseIndex = 0; exerciseIndex < exercises.length; exerciseIndex++) {
    let item: ExerciseRecordItem = exercises[exerciseIndex];
    lines.push(`exercise,${item.dayKey},${item.time},${sanitizeCsvCell(`${item.name} ${item.duration}\u5206\u949f`)},${item.calories},kcal`);
  }
  return lines.join('\n');
}

export function updateFavoriteFood(favorites: FavoriteFoodItem[], favoriteId: number, name: string,
  calories: number, updatedAt: string): FavoriteFoodItem[] {
  let safeName: string = name.trim();
  let safeCalories: number = Math.max(1, Math.round(calories));
  let next: FavoriteFoodItem[] = [];
  for (let index = 0; index < favorites.length; index++) {
    let item: FavoriteFoodItem = favorites[index];
    if (item.id === favoriteId && safeName.length > 0) {
      next.push({
        id: item.id,
        name: safeName,
        calories: safeCalories,
        source: item.source,
        lastUsedAt: updatedAt
      });
    } else {
      next.push(item);
    }
  }
  return next;
}

export function deleteFavoriteFood(favorites: FavoriteFoodItem[], favoriteId: number): FavoriteFoodItem[] {
  let next: FavoriteFoodItem[] = [];
  for (let index = 0; index < favorites.length; index++) {
    if (favorites[index].id !== favoriteId) {
      next.push(favorites[index]);
    }
  }
  return next;
}

export function firstWeightForDay(records: WeightRecordItem[], dayKey: string): number {
  let selected: WeightRecordItem | null = null;
  for (let index = 0; index < records.length; index++) {
    let item: WeightRecordItem = records[index];
    if (item.dayKey !== dayKey) {
      continue;
    }
    if (selected === null || item.id < selected.id) {
      selected = item;
    }
  }
  return selected === null ? 0 : selected.value;
}

export function latestWeightForDay(records: WeightRecordItem[], dayKey: string): number {
  let selected: WeightRecordItem | null = null;
  for (let index = 0; index < records.length; index++) {
    let item: WeightRecordItem = records[index];
    if (item.dayKey !== dayKey) {
      continue;
    }
    if (selected === null || item.id > selected.id) {
      selected = item;
    }
  }
  return selected === null ? 0 : selected.value;
}

export function calculateWeekLoss(records: WeightRecordItem[], currentWeight: number, weekDayKeys: string[]): number {
  for (let index = 0; index < weekDayKeys.length; index++) {
    let startWeight: number = firstWeightForDay(records, weekDayKeys[index]);
    if (startWeight > 0) {
      return Number((startWeight - currentWeight).toFixed(2));
    }
  }
  return 0;
}

export function upsertWeightRecordKeepingBaseline(records: WeightRecordItem[],
  nextRecord: WeightRecordItem): WeightRecordItem[] {
  let next: WeightRecordItem[] = [];
  let sameDay: WeightRecordItem[] = [];

  for (let index = 0; index < records.length; index++) {
    let item: WeightRecordItem = records[index];
    if (item.dayKey === nextRecord.dayKey) {
      sameDay.push(item);
    } else {
      next.push(item);
    }
  }

  if (sameDay.length === 0) {
    next.push(nextRecord);
  } else {
    let baseline: WeightRecordItem = sameDay[0];
    for (let index = 1; index < sameDay.length; index++) {
      if (sameDay[index].id < baseline.id) {
        baseline = sameDay[index];
      }
    }
    next.push(baseline);
    if (baseline.id !== nextRecord.id || baseline.value !== nextRecord.value || baseline.time !== nextRecord.time) {
      next.push(nextRecord);
    }
  }

  next.sort((left: WeightRecordItem, right: WeightRecordItem) => {
    let dayCompare: number = right.dayKey.localeCompare(left.dayKey);
    if (dayCompare !== 0) {
      return dayCompare;
    }
    return right.id - left.id;
  });
  return next;
}

function mealCaloriesForDay(records: MealRecordItem[], dayKey: string): number {
  let total: number = 0;
  for (let index = 0; index < records.length; index++) {
    if (records[index].dayKey === dayKey) {
      total += records[index].calories;
    }
  }
  return total;
}

function waterAmountForDay(records: WaterRecordItem[], dayKey: string): number {
  let total: number = 0;
  for (let index = 0; index < records.length; index++) {
    if (records[index].dayKey === dayKey) {
      total += records[index].amount;
    }
  }
  return total;
}

function exerciseCaloriesForDay(records: ExerciseRecordItem[], dayKey: string): number {
  let total: number = 0;
  for (let index = 0; index < records.length; index++) {
    if (records[index].dayKey === dayKey) {
      total += records[index].calories;
    }
  }
  return total;
}

function weightForDay(records: WeightRecordItem[], dayKey: string): number {
  return latestWeightForDay(records, dayKey);
}

function sanitizeCsvCell(value: string): string {
  return value.replace(',', '\uff0c').replace('\n', ' ');
}

function dateFromDayKey(dayKey: string): Date {
  let parts: string[] = dayKey.split('-');
  if (parts.length !== 3) {
    return new Date();
  }
  let year: number = Number(parts[0]);
  let month: number = Number(parts[1]);
  let day: number = Number(parts[2]);
  return new Date(year, month - 1, day);
}

function dayKeyFromDate(date: Date): string {
  let year: string = date.getFullYear().toString();
  let month: string = (date.getMonth() + 1).toString().padStart(2, '0');
  let day: string = date.getDate().toString().padStart(2, '0');
  return `${year}-${month}-${day}`;
}
