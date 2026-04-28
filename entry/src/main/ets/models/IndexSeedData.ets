import { ChatMessage } from './AppState';
import { ProfileMenuItem, SuggestionItem } from './PageModels';
import { DrinkPresetItem, ExerciseCategoryItem, ExercisePresetItem, MealActionItem, MealPresetItem } from './IndexModels';

export function createDefaultMessages(): ChatMessage[] {
  return [
    {
      id: 1,
      role: 'assistant',
      content: '\u55e8\uff0c\u6211\u662f\u4f60\u7684 AI \u5065\u5eb7\u52a9\u624b\u3002\u4f60\u53ef\u4ee5\u95ee\u6211\u996e\u98df\u3001\u4f53\u91cd\u6ce2\u52a8\u548c\u8fd0\u52a8\u5b89\u6392\uff0c\u6211\u4f1a\u7ed3\u5408\u5f53\u524d\u8bb0\u5f55\u7ed9\u4f60\u5efa\u8bae\u3002'
    }
  ];
}

export const AI_SUGGESTIONS: SuggestionItem[] = [
  { id: 1, label: '\u751f\u6210\u672c\u5468AI\u5468\u62a5', tint: '#4B8DFF', bgColor: '#EEF4FF' },
  { id: 2, label: '\u4eca\u5929\u8fd8\u80fd\u5403\u591a\u5c11\uff1f', tint: '#36C79A', bgColor: '#ECFBF5' },
  { id: 3, label: '\u660e\u5929\u8fd0\u52a8\u600e\u4e48\u5b89\u6392\uff1f', tint: '#FF9D4D', bgColor: '#FFF4EA' }
];

export const PROFILE_MENU_ITEMS: ProfileMenuItem[] = [
  {
    id: 1,
    title: '\u5468\u62a5\u5206\u6790',
    subtitle: '\u56de\u770b\u4f60\u7684\u996e\u98df\u3001\u4f53\u91cd\u548c\u8fd0\u52a8\u8d8b\u52bf',
    glyph: '\u5468',
    tint: '#4B8DFF',
    bgColor: '#EEF4FF',
    badge: 'NEW'
  },
  {
    id: 2,
    title: '\u6211\u7684\u76ee\u6807',
    subtitle: '\u76ee\u524d\u76ee\u6807\uff1a\u6bcf\u5468\u7a33\u5b9a\u51cf\u91cd 0.3kg',
    glyph: '\u9776',
    tint: '#FF9D4D',
    bgColor: '#FFF7EE',
    badge: ''
  },
  {
    id: 3,
    title: '\u8d26\u53f7\u5b89\u5168',
    subtitle: '\u7ba1\u7406\u767b\u5f55\u65b9\u5f0f\u4e0e\u9690\u79c1\u8bbe\u7f6e',
    glyph: '\u5b89',
    tint: '#36C79A',
    bgColor: '#ECFBF5',
    badge: ''
  },
  {
    id: 4,
    title: '\u5e2e\u52a9\u4e0e\u53cd\u9988',
    subtitle: '\u628a\u4f60\u60f3\u8981\u7684\u529f\u80fd\u544a\u8bc9\u6211\u4eec',
    glyph: '\u95ee',
    tint: '#94A3B8',
    bgColor: '#F8FAFC',
    badge: ''
  }
];

export const MEAL_ACTIONS: MealActionItem[] = [
  { id: 1, type: 'breakfast', label: '\u65e9\u9910', glyph: '\u65e9', tint: '#FF9D4D', bgColor: '#FFF7EE' },
  { id: 2, type: 'lunch', label: '\u5348\u9910', glyph: '\u5348', tint: '#4B8DFF', bgColor: '#EEF4FF' },
  { id: 3, type: 'dinner', label: '\u665a\u9910', glyph: '\u665a', tint: '#8B5CF6', bgColor: '#F4EEFF' },
  { id: 4, type: 'snack', label: '\u52a0\u9910', glyph: '\u52a0', tint: '#F97316', bgColor: '#FFF3EA' },
  { id: 5, type: 'exercise', label: '\u8fd0\u52a8', glyph: '\u52a8', tint: '#36C79A', bgColor: '#ECFBF5' }
];

export const MEAL_PRESETS: MealPresetItem[] = [
  { id: 1, mealType: 'breakfast', name: '\u6c34\u716e\u86cb', calories: 78, subtitle: '\u9ad8\u86cb\u767d' },
  { id: 2, mealType: 'breakfast', name: '\u5168\u9ea6\u5410\u53f8', calories: 92, subtitle: '\u6162\u78b3\u6c34' },
  { id: 3, mealType: 'breakfast', name: '\u65e0\u7cd6\u8c46\u6d46', calories: 88, subtitle: '\u6e29\u548c\u9965\u8179' },
  { id: 4, mealType: 'breakfast', name: '\u5e0c\u814a\u9178\u5976', calories: 105, subtitle: '\u8f7b\u76c8\u642d\u914d' },
  { id: 5, mealType: 'lunch', name: '\u7cd9\u7c73\u996d', calories: 116, subtitle: '\u4e3b\u98df' },
  { id: 6, mealType: 'lunch', name: '\u9999\u714e\u9e21\u80f8', calories: 168, subtitle: '\u4f18\u8d28\u86cb\u767d' },
  { id: 7, mealType: 'lunch', name: '\u6e05\u7092\u897f\u5170\u82b1', calories: 84, subtitle: '\u8535\u83dc' },
  { id: 8, mealType: 'lunch', name: '\u725b\u6cb9\u83dc\u6c99\u62c9', calories: 132, subtitle: '\u8f7b\u98df' },
  { id: 9, mealType: 'dinner', name: '\u5357\u74dc\u6d53\u6c64', calories: 96, subtitle: '\u6696\u80c3' },
  { id: 10, mealType: 'dinner', name: '\u9999\u714e\u867e\u4ec1', calories: 124, subtitle: '\u9ad8\u86cb\u767d' },
  { id: 11, mealType: 'dinner', name: '\u84b8\u7d2b\u85af', calories: 112, subtitle: '\u4f4e\u8d1f\u62c5' },
  { id: 12, mealType: 'dinner', name: '\u51c9\u62cc\u9ec4\u74dc', calories: 42, subtitle: '\u6e05\u723d' },
  { id: 13, mealType: 'snack', name: '\u84dd\u8393', calories: 45, subtitle: '\u6c34\u679c' },
  { id: 14, mealType: 'snack', name: '\u575a\u679c\u5c0f\u628a', calories: 96, subtitle: '\u63a7\u91cf' },
  { id: 15, mealType: 'snack', name: '\u9ad8\u86cb\u767d\u5976', calories: 118, subtitle: '\u8865\u80fd\u91cf' }
];

export const EXERCISE_CATEGORIES: ExerciseCategoryItem[] = [
  { id: 1, label: '\u70ed\u95e8', tint: '#36C79A', bgColor: '#ECFBF5', glyph: '\u70ed' },
  { id: 2, label: '\u6b65\u884c', tint: '#4B8DFF', bgColor: '#EEF4FF', glyph: '\u6b65' },
  { id: 3, label: '\u8dd1\u6b65', tint: '#F97316', bgColor: '#FFF3EA', glyph: '\u8dd1' },
  { id: 4, label: '\u9a91\u884c', tint: '#8B5CF6', bgColor: '#F4EEFF', glyph: '\u9a91' },
  { id: 5, label: '\u7403\u7c7b', tint: '#F59E0B', bgColor: '#FFF7E8', glyph: '\u7403' },
  { id: 6, label: '\u5065\u8eab', tint: '#0EA5E9', bgColor: '#E8F7FF', glyph: '\u529b' },
  { id: 7, label: '\u62c9\u4f38', tint: '#14B8A6', bgColor: '#E8FCF8', glyph: '\u4f38' }
];

export const EXERCISE_PRESETS: ExercisePresetItem[] = [
  { id: 1, category: '\u70ed\u95e8', name: '\u8dd1\u6b65\u673a\u722c\u5761', calories: 673, duration: 60, glyph: '\u5761', bgColor: '#FFF3EA' },
  { id: 2, category: '\u70ed\u95e8', name: '\u5feb\u8d70', calories: 250, duration: 45, glyph: '\u8d70', bgColor: '#EEF4FF' },
  { id: 3, category: '\u70ed\u95e8', name: '\u8df3\u7ef3', calories: 648, duration: 60, glyph: '\u7ef3', bgColor: '#FFF7E8' },
  { id: 4, category: '\u70ed\u95e8', name: '\u6668\u8d77\u62c9\u4f38', calories: 120, duration: 30, glyph: '\u4f38', bgColor: '#E8FCF8' },
  { id: 5, category: '\u6b65\u884c', name: '\u901a\u52e4\u6563\u6b65', calories: 180, duration: 35, glyph: '\u6b65', bgColor: '#EEF4FF' },
  { id: 6, category: '\u6b65\u884c', name: '\u6237\u5916\u5feb\u8d70', calories: 291, duration: 60, glyph: '\u901f', bgColor: '#EEF4FF' },
  { id: 7, category: '\u8dd1\u6b65', name: '\u6237\u5916\u6162\u8dd1', calories: 415, duration: 50, glyph: '\u8dd1', bgColor: '#FFF3EA' },
  { id: 8, category: '\u8dd1\u6b65', name: 'HIIT \u95f4\u6b47\u8dd1', calories: 540, duration: 40, glyph: 'HI', bgColor: '#FFF3EA' },
  { id: 9, category: '\u9a91\u884c', name: '\u5ba4\u5185\u5355\u8f66', calories: 388, duration: 45, glyph: '\u9a91', bgColor: '#F4EEFF' },
  { id: 10, category: '\u9a91\u884c', name: '\u901a\u52e4\u9a91\u884c', calories: 320, duration: 40, glyph: '\u8f66', bgColor: '#F4EEFF' },
  { id: 11, category: '\u7403\u7c7b', name: '\u7fbd\u6bdb\u7403', calories: 430, duration: 60, glyph: '\u7fbd', bgColor: '#FFF7E8' },
  { id: 12, category: '\u7403\u7c7b', name: '\u7bee\u7403', calories: 468, duration: 60, glyph: '\u7bee', bgColor: '#FFF7E8' },
  { id: 13, category: '\u5065\u8eab', name: '\u81ea\u91cd\u5faa\u73af\u8bad\u7ec3', calories: 352, duration: 45, glyph: '\u529b', bgColor: '#E8F7FF' },
  { id: 14, category: '\u5065\u8eab', name: '\u54d1\u94c3\u8bad\u7ec3', calories: 300, duration: 50, glyph: '\u94c3', bgColor: '#E8F7FF' },
  { id: 15, category: '\u62c9\u4f38', name: '\u7761\u524d\u745c\u4f3d', calories: 145, duration: 35, glyph: '\u745c', bgColor: '#E8FCF8' },
  { id: 16, category: '\u62c9\u4f38', name: '\u808c\u8089\u653e\u677e', calories: 96, duration: 25, glyph: '\u677e', bgColor: '#E8FCF8' }
];

export const WATER_PRESETS: DrinkPresetItem[] = [
  { id: 1, label: '\u6c34', glyph: '\u6c34', tint: '#32C5F4', bgColor: '#E9F9FF' },
  { id: 2, label: '\u8336\u6c34', glyph: '\u8336', tint: '#F59E0B', bgColor: '#FFF7E8' },
  { id: 3, label: '\u82cf\u6253\u6c34', glyph: '\u6c14', tint: '#60A5FA', bgColor: '#EEF4FF' },
  { id: 4, label: '\u5496\u5561', glyph: '\u5496', tint: '#8B5E3C', bgColor: '#F8F2EC' },
  { id: 5, label: '\u6930\u5976', glyph: '\u6930', tint: '#F59E0B', bgColor: '#FFF7EE' },
  { id: 6, label: '\u67e0\u6aac\u6c34', glyph: '\u67e0', tint: '#FACC15', bgColor: '#FFFCE8' },
  { id: 7, label: '\u82f9\u679c\u918b', glyph: '\u918b', tint: '#FB7185', bgColor: '#FFF1F2' },
  { id: 8, label: '\u7ea2\u7cd6\u6c34', glyph: '\u7cd6', tint: '#EF4444', bgColor: '#FEF2F2' },
  { id: 9, label: '\u8c46\u6d46', glyph: '\u8c46', tint: '#F59E0B', bgColor: '#FFF7EE' },
  { id: 10, label: '\u7ca5', glyph: '\u7ca5', tint: '#94A3B8', bgColor: '#F8FAFC' },
  { id: 11, label: '\u8c46\u5976', glyph: '\u5976', tint: '#F59E0B', bgColor: '#FFF7EE' },
  { id: 12, label: '\u53ef\u4e50', glyph: '\u4e50', tint: '#F43F5E', bgColor: '#FFF1F2' },
  { id: 13, label: '\u725b\u5976', glyph: '\u725b', tint: '#06B6D4', bgColor: '#ECFEFF' },
  { id: 14, label: '\u679c\u6c41', glyph: '\u679c', tint: '#FB923C', bgColor: '#FFF7ED' },
  { id: 15, label: '\u9178\u6885\u6c64', glyph: '\u6885', tint: '#E11D48', bgColor: '#FFF1F2' },
  { id: 16, label: '\u9178\u5976', glyph: '\u9178', tint: '#38BDF8', bgColor: '#F0F9FF' },
  { id: 17, label: '\u5976\u8336', glyph: '\u5976', tint: '#F59E0B', bgColor: '#FFF7EE' },
  { id: 18, label: '\u517b\u4e50\u591a', glyph: '\u517b', tint: '#FB7185', bgColor: '#FFF1F2' }
];
