import { ExerciseRecordItem } from './AppState';
import { ExercisePresetItem } from './IndexModels';

export function exerciseWeekLabels(): string[] {
  return ['\u4e00', '\u4e8c', '\u4e09', '\u56db', '\u4e94', '\u516d', '\u65e5'];
}

export function exerciseOptionsForCategory(presets: ExercisePresetItem[], category: string,
  keywordText: string): ExercisePresetItem[] {
  let options: ExercisePresetItem[] = [];
  let keyword: string = keywordText.trim().toLowerCase();
  for (let index = 0; index < presets.length; index++) {
    let item: ExercisePresetItem = presets[index];
    let matchesCategory: boolean = item.category === category;
    let matchesKeyword: boolean = keyword.length === 0 || item.name.toLowerCase().includes(keyword);
    if (matchesCategory && matchesKeyword) {
      options.push(item);
    }
  }
  return options;
}

export function exerciseRecordsForDay(records: ExerciseRecordItem[], dayKey: string): ExerciseRecordItem[] {
  let dayRecords: ExerciseRecordItem[] = [];
  for (let index = 0; index < records.length; index++) {
    let item: ExerciseRecordItem = records[index];
    if (item.dayKey === dayKey) {
      dayRecords.push(item);
    }
  }
  return dayRecords;
}

export function exerciseDurationValue(draft: string, defaultDuration: number = 0): number {
  if (draft.length > 0) {
    let parsedValue: number = Number(draft);
    if (!Number.isNaN(parsedValue) && parsedValue > 0) {
      return Math.round(parsedValue);
    }
  }
  return defaultDuration;
}

export function exerciseCaloriesForDuration(item: ExercisePresetItem, duration: number): number {
  if (item.duration <= 0) {
    return item.calories;
  }
  return Math.max(1, Math.round((item.calories * duration) / item.duration));
}

export function selectedExerciseCalories(presets: ExercisePresetItem[], selectedExerciseId: number,
  durationDraft: string): number {
  for (let index = 0; index < presets.length; index++) {
    let item: ExercisePresetItem = presets[index];
    if (item.id === selectedExerciseId) {
      let duration: number = exerciseDurationValue(durationDraft, item.duration);
      return exerciseCaloriesForDuration(item, duration);
    }
  }
  return 0;
}

export function exerciseWeekCalories(records: ExerciseRecordItem[], weekDayKeys: string[]): number[] {
  let values: number[] = [0, 0, 0, 0, 0, 0, 0];
  for (let recordIndex = 0; recordIndex < records.length; recordIndex++) {
    let record: ExerciseRecordItem = records[recordIndex];
    for (let keyIndex = 0; keyIndex < weekDayKeys.length; keyIndex++) {
      if (record.dayKey === weekDayKeys[keyIndex]) {
        values[keyIndex] += record.calories;
        break;
      }
    }
  }
  return values;
}

export function exerciseGoalDaysThisWeek(values: number[]): number {
  let count: number = 0;
  for (let index = 0; index < values.length; index++) {
    if (values[index] > 0) {
      count += 1;
    }
  }
  return count;
}

export function exerciseDailyAverage(values: number[]): number {
  let total: number = 0;
  for (let index = 0; index < values.length; index++) {
    total += values[index];
  }
  if (total <= 0) {
    return 0;
  }
  return Math.round(total / 7);
}

export function exerciseBarHeights(values: number[]): number[] {
  let maxValue: number = 0;
  for (let index = 0; index < values.length; index++) {
    if (values[index] > maxValue) {
      maxValue = values[index];
    }
  }
  if (maxValue <= 0) {
    return [8, 8, 8, 8, 8, 8, 8];
  }

  let heights: number[] = [];
  for (let index = 0; index < values.length; index++) {
    let height: number = Math.round((values[index] / maxValue) * 64);
    heights.push(Math.max(8, height));
  }
  return heights;
}

export function exerciseAdjustedCalories(calories: number): number {
  return Math.round(calories * 0.9);
}
