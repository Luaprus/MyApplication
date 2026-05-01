import { SuggestionItem } from './PageModels';

export interface AiSuggestionContext {
  water: number;
  waterGoal: number;
  dinnerCalories: number;
  exerciseCalories: number;
  daysSinceWeight: number;
  weekLoss: number;
}

export const WEEKLY_REPORT_LABEL: string = '\u751f\u6210\u672c\u5468AI\u5468\u62a5';

export function buildAiSuggestions(context: AiSuggestionContext): SuggestionItem[] {
  let suggestions: SuggestionItem[] = [
    { id: 1, label: WEEKLY_REPORT_LABEL, tint: '#4B8DFF', bgColor: '#EEF4FF' }
  ];

  if (context.waterGoal > 0 && context.water < context.waterGoal * 0.7) {
    suggestions.push({
      id: 2,
      label: '\u4eca\u5929\u996e\u6c34\u8fd8\u5dee\u591a\u5c11\uff1f',
      tint: '#32C5F4',
      bgColor: '#E9F9FF'
    });
  }

  if (context.dinnerCalories <= 0) {
    suggestions.push({
      id: 3,
      label: '\u665a\u9910\u600e\u4e48\u5403\u66f4\u7a33\uff1f',
      tint: '#8B5CF6',
      bgColor: '#F4EEFF'
    });
  }

  if (context.exerciseCalories < 180) {
    suggestions.push({
      id: 4,
      label: '\u5e2e\u6211\u5b89\u6392 20 \u5206\u949f\u8fd0\u52a8',
      tint: '#36C79A',
      bgColor: '#ECFBF5'
    });
  }

  if (context.daysSinceWeight >= 3) {
    suggestions.push({
      id: 5,
      label: '\u4f53\u91cd\u51e0\u5929\u6ca1\u8bb0\u4f1a\u5f71\u54cd\u8d8b\u52bf\u5417\uff1f',
      tint: '#F97316',
      bgColor: '#FFF3EA'
    });
  }

  if (suggestions.length < 3 && context.weekLoss < 0) {
    suggestions.push({
      id: 6,
      label: '\u672c\u5468\u4f53\u91cd\u4e0a\u6d6e\u600e\u4e48\u8c03\u6574\uff1f',
      tint: '#EF4444',
      bgColor: '#FEF2F2'
    });
  }

  if (suggestions.length < 3) {
    suggestions.push({
      id: 7,
      label: '\u4eca\u5929\u8fd8\u80fd\u5403\u591a\u5c11\uff1f',
      tint: '#36C79A',
      bgColor: '#ECFBF5'
    });
  }

  if (suggestions.length < 3) {
    suggestions.push({
      id: 8,
      label: '\u660e\u5929\u8fd0\u52a8\u600e\u4e48\u5b89\u6392\uff1f',
      tint: '#FF9D4D',
      bgColor: '#FFF4EA'
    });
  }

  return suggestions.slice(0, 3);
}
