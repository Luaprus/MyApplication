import { WaterRecordItem } from './AppState';
import { DrinkPresetItem } from './IndexModels';

export function waterGoalMl(weightKg: number): number {
  let baseGoal: number = Math.round(weightKg * 35);
  if (baseGoal < 1500) {
    baseGoal = 1500;
  }
  if (baseGoal > 2800) {
    baseGoal = 2800;
  }
  return Math.round(baseGoal / 50) * 50;
}

export function waterProgressPercent(total: number, goalMl: number): number {
  if (goalMl <= 0) {
    return 0;
  }
  return Math.min(100, Math.round((total / goalMl) * 100));
}

export function waterRecordsForDay(records: WaterRecordItem[], dayKey: string): WaterRecordItem[] {
  let dayRecords: WaterRecordItem[] = [];
  for (let index = 0; index < records.length; index++) {
    if (records[index].dayKey === dayKey) {
      dayRecords.push(records[index]);
    }
  }
  return dayRecords;
}

export function latestWaterRecordForDisplay(records: WaterRecordItem[], dayKey: string,
  total: number): WaterRecordItem | null {
  let todayRecords: WaterRecordItem[] = waterRecordsForDay(records, dayKey);
  if (todayRecords.length > 0) {
    return todayRecords[0];
  }
  if (total > 0 && records.length > 0) {
    return records[0];
  }
  return null;
}

export function latestWaterRecord(records: WaterRecordItem[], dayKey: string): WaterRecordItem | null {
  let todayRecords: WaterRecordItem[] = waterRecordsForDay(records, dayKey);
  if (todayRecords.length === 0) {
    return null;
  }
  return todayRecords[0];
}

export function waterPresetRows(presets: DrinkPresetItem[]): DrinkPresetItem[][] {
  let rows: DrinkPresetItem[][] = [];
  for (let index = 0; index < presets.length; index += 3) {
    rows.push(presets.slice(index, index + 3));
  }
  return rows;
}

export function selectedDrinkName(presets: DrinkPresetItem[], selectedDrinkId: number): string {
  for (let index = 0; index < presets.length; index++) {
    if (presets[index].id === selectedDrinkId) {
      return presets[index].label;
    }
  }
  return '\u6c34';
}
