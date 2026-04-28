import { WeightRecordItem } from './AppState';
import { currentDayKey, dateFromDayKey } from './DateTimeUtils';

export function clampUnitProgress(value: number): number {
  if (value < 0) {
    return 0;
  }
  if (value > 1) {
    return 1;
  }
  return value;
}

export function progressWidth(value: number): string {
  let percentage: number = Math.round(clampUnitProgress(value) * 100);
  if (percentage > 0 && percentage < 8) {
    percentage = 8;
  }
  return `${percentage}%`;
}

export function clampWeightKg(weightKg: number): number {
  if (weightKg < 30) {
    return 30;
  }
  if (weightKg > 150) {
    return 150;
  }
  return Number(weightKg.toFixed(2));
}

export function parseWeightPlanWeeklyTarget(profileWeeklyTarget: string, onboardingWeeklyTarget: string): number {
  let profileTarget: number = Number(profileWeeklyTarget.trim());
  if (!Number.isNaN(profileTarget) && profileTarget > 0) {
    return Number(profileTarget.toFixed(2));
  }
  let onboardingTarget: number = Number(onboardingWeeklyTarget.trim());
  if (!Number.isNaN(onboardingTarget) && onboardingTarget > 0) {
    return Number(onboardingTarget.toFixed(2));
  }
  return 0.3;
}

export function weightPlanTargetWeight(onboardingTargetWeight: string, currentWeight: number): number {
  let parsedTarget: number = Number(onboardingTargetWeight.trim());
  if (!Number.isNaN(parsedTarget) && parsedTarget > 0) {
    return clampWeightKg(parsedTarget);
  }
  return clampWeightKg(Math.max(currentWeight - 1, 30));
}

export function weightPlanStartWeight(records: WeightRecordItem[], currentWeight: number): number {
  if (records.length === 0) {
    return currentWeight;
  }

  let oldestRecord: WeightRecordItem = records[0];
  for (let index = 1; index < records.length; index++) {
    if (records[index].dayKey < oldestRecord.dayKey) {
      oldestRecord = records[index];
    }
  }
  return oldestRecord.value;
}

export function weightPlanWeekNumber(records: WeightRecordItem[], todayKey: string = currentDayKey()): number {
  if (records.length === 0) {
    return 1;
  }

  let earliestDayKey: string = records[0].dayKey;
  for (let index = 1; index < records.length; index++) {
    if (records[index].dayKey < earliestDayKey) {
      earliestDayKey = records[index].dayKey;
    }
  }

  let firstDate: Date = dateFromDayKey(earliestDayKey);
  let today: Date = dateFromDayKey(todayKey);
  let distance: number = Math.max(0, today.getTime() - firstDate.getTime());
  return Math.floor(distance / 604800000) + 1;
}

export function weightPlanValueText(weekLoss: number): string {
  if (weekLoss < 0) {
    return `+${Math.abs(weekLoss).toFixed(2)}`;
  }
  return weekLoss.toFixed(2);
}

export function weightPlanValueLabel(weekLoss: number): string {
  if (weekLoss < 0) {
    return '\u672c\u5468\u53d8\u5316\uff08\u516c\u65a4\uff09';
  }
  return '\u672c\u5468\u51cf\u91cd\uff08\u516c\u65a4\uff09';
}

export function displayWeightDraft(weightKg: number, unit: 'kg' | 'jin'): string {
  if (unit === 'jin') {
    return (weightKg * 2).toFixed(2);
  }
  return weightKg.toFixed(2);
}

export function weightDraftToKg(draft: string, unit: 'kg' | 'jin', fallbackWeightKg: number): number {
  let parsed: number = Number(draft);
  if (Number.isNaN(parsed) || parsed <= 0) {
    return fallbackWeightKg;
  }
  if (unit === 'jin') {
    return parsed / 2;
  }
  return parsed;
}
