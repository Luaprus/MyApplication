import { MealRecordItem, MealType } from './AppState';

export interface MealCalorieTotals {
  total: number;
  breakfast: number;
  lunch: number;
  dinner: number;
  snack: number;
}

export function mealCalorieTotals(records: MealRecordItem[], dayKey: string,
  scannedCaloriesTotal: number): MealCalorieTotals {
  let totals: MealCalorieTotals = {
    total: scannedCaloriesTotal,
    breakfast: 0,
    lunch: 0,
    dinner: 0,
    snack: 0
  };

  records.forEach((item: MealRecordItem) => {
    if (item.dayKey !== dayKey) {
      return;
    }
    totals.total += item.calories;
    if (item.mealType === 'breakfast') {
      totals.breakfast += item.calories;
    } else if (item.mealType === 'lunch') {
      totals.lunch += item.calories;
    } else if (item.mealType === 'dinner') {
      totals.dinner += item.calories;
    } else {
      totals.snack += item.calories;
    }
  });

  totals.total = Math.max(0, totals.total);
  return totals;
}

export function mealCaloriesForType(records: MealRecordItem[], dayKey: string, type: MealType): number {
  let total: number = 0;
  records.forEach((item: MealRecordItem) => {
    if (item.dayKey === dayKey && item.mealType === type) {
      total += item.calories;
    }
  });
  return total;
}

export function currentMealCaloriesValue(activeMealType: MealType, totals: MealCalorieTotals): number {
  if (activeMealType === 'breakfast') {
    return totals.breakfast;
  }
  if (activeMealType === 'lunch') {
    return totals.lunch;
  }
  if (activeMealType === 'dinner') {
    return totals.dinner;
  }
  return totals.snack;
}

export function mealRecordsForType(records: MealRecordItem[], dayKey: string,
  activeMealType: MealType): MealRecordItem[] {
  return records
    .filter((item: MealRecordItem) => item.dayKey === dayKey && item.mealType === activeMealType)
    .sort((left: MealRecordItem, right: MealRecordItem) => right.id - left.id);
}

export function applyMealCaloriesDelta(totals: MealCalorieTotals, type: MealType,
  delta: number, scannedCaloriesTotal: number): MealCalorieTotals {
  let next: MealCalorieTotals = {
    total: totals.total,
    breakfast: totals.breakfast,
    lunch: totals.lunch,
    dinner: totals.dinner,
    snack: totals.snack
  };

  if (type === 'breakfast') {
    next.breakfast = Math.max(0, next.breakfast + delta);
  } else if (type === 'lunch') {
    next.lunch = Math.max(0, next.lunch + delta);
  } else if (type === 'dinner') {
    next.dinner = Math.max(0, next.dinner + delta);
  } else {
    next.snack = Math.max(0, next.snack + delta);
  }
  next.total = Math.max(0, scannedCaloriesTotal + next.breakfast + next.lunch + next.dinner + next.snack);
  return next;
}
