import { FavoriteFoodItem, MealType } from './AppState';
import { MealPresetItem } from './IndexModels';

export function mealPresetRows(presets: MealPresetItem[], activeMealType: MealType): MealPresetItem[][] {
  let filtered: MealPresetItem[] = presets.filter((item: MealPresetItem) => item.mealType === activeMealType);
  let rows: MealPresetItem[][] = [];
  for (let index = 0; index < filtered.length; index += 2) {
    rows.push(filtered.slice(index, index + 2));
  }
  return rows;
}

export function favoriteFoodRows(favorites: FavoriteFoodItem[]): FavoriteFoodItem[][] {
  let rows: FavoriteFoodItem[][] = [];
  for (let index = 0; index < favorites.length; index += 2) {
    rows.push(favorites.slice(index, index + 2));
  }
  return rows;
}

export function favoriteFoodRowKey(row: FavoriteFoodItem[]): string {
  let ids: string[] = [];
  row.forEach((item: FavoriteFoodItem) => {
    ids.push(item.id.toString());
  });
  return ids.join('-');
}

export function mealPresetRowKey(row: MealPresetItem[]): string {
  let ids: string[] = [];
  row.forEach((item: MealPresetItem) => {
    ids.push(item.id.toString());
  });
  return ids.join('-');
}
