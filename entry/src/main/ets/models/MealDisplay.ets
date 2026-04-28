import { MealType } from './AppState';

export function mealDisplayName(type: MealType): string {
  if (type === 'breakfast') {
    return '\u65e9\u9910\u8bb0\u5f55';
  }
  if (type === 'lunch') {
    return '\u5348\u9910\u8bb0\u5f55';
  }
  if (type === 'dinner') {
    return '\u665a\u9910\u8bb0\u5f55';
  }
  return '\u52a0\u9910\u8bb0\u5f55';
}

export function mealLabel(type: MealType): string {
  if (type === 'breakfast') {
    return '\u65e9\u9910';
  }
  if (type === 'lunch') {
    return '\u5348\u9910';
  }
  if (type === 'dinner') {
    return '\u665a\u9910';
  }
  return '\u52a0\u9910';
}

export function mealTint(type: MealType): string {
  if (type === 'breakfast') {
    return '#FF9D4D';
  }
  if (type === 'lunch') {
    return '#4B8DFF';
  }
  if (type === 'dinner') {
    return '#8B5CF6';
  }
  return '#F97316';
}

export function mealBgColor(type: MealType): string {
  if (type === 'breakfast') {
    return '#FFF7EE';
  }
  if (type === 'lunch') {
    return '#EEF4FF';
  }
  if (type === 'dinner') {
    return '#F4EEFF';
  }
  return '#FFF3EA';
}

export function healthLightLabel(value: number): string {
  if (value === 1) {
    return '\u7eff\u706f';
  }
  if (value === 2) {
    return '\u9ec4\u706f';
  }
  if (value === 3) {
    return '\u7ea2\u706f';
  }
  return '\u4e2d\u6027';
}

export function healthLightColor(value: number): string {
  if (value === 1) {
    return '#36C79A';
  }
  if (value === 2) {
    return '#F59E0B';
  }
  if (value === 3) {
    return '#EF4444';
  }
  return '#94A3B8';
}
