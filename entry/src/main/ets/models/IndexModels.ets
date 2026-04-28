import { MealType } from './AppState';

export interface MealActionItem {
  id: number;
  type: MealType | 'exercise';
  label: string;
  glyph: string;
  tint: string;
  bgColor: string;
}

export interface MealPresetItem {
  id: number;
  mealType: MealType;
  name: string;
  calories: number;
  subtitle: string;
}

export interface ExerciseCategoryItem {
  id: number;
  label: string;
  tint: string;
  bgColor: string;
  glyph: string;
}

export interface ExercisePresetItem {
  id: number;
  category: string;
  name: string;
  calories: number;
  duration: number;
  glyph: string;
  bgColor: string;
}

export interface DrinkPresetItem {
  id: number;
  label: string;
  glyph: string;
  tint: string;
  bgColor: string;
}

export type ProfilePanelType = 'none' | 'settings' | 'weekly' | 'goal' | 'security' | 'feedback' | 'benefits';

export interface WeeklyWeightPoint {
  label: string;
  value: number;
}
