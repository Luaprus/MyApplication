import { MealType } from './AppState';
import { ProfilePanelType } from './IndexModels';

export function waterPresetIcon(id: number) {
  switch (id) {
    case 1:
      return $r('app.media.icon_drink_water');
    case 2:
      return $r('app.media.icon_drink_tea');
    case 3:
      return $r('app.media.icon_drink_soda');
    case 4:
      return $r('app.media.icon_drink_coffee');
    case 5:
      return $r('app.media.icon_drink_coconut');
    case 6:
      return $r('app.media.icon_drink_lemon');
    case 7:
      return $r('app.media.icon_drink_apple_cider');
    case 8:
      return $r('app.media.icon_drink_brown_sugar');
    case 9:
      return $r('app.media.icon_drink_soy_milk_cup');
    case 10:
      return $r('app.media.icon_drink_porridge');
    case 11:
      return $r('app.media.icon_drink_soy_milk_bottle');
    case 12:
      return $r('app.media.icon_drink_cola');
    case 13:
      return $r('app.media.icon_drink_milk');
    case 14:
      return $r('app.media.icon_drink_juice');
    case 15:
      return $r('app.media.icon_drink_sour_plum');
    case 16:
      return $r('app.media.icon_drink_yogurt');
    case 17:
      return $r('app.media.icon_drink_milk_tea');
    case 18:
      return $r('app.media.icon_drink_yakult');
    default:
      return undefined;
  }
}

export function profileStatIcon(glyph: string) {
  switch (glyph) {
    case '\u62a5':
      return $r('app.media.icon_profile_report');
    case '\u793c':
      return $r('app.media.icon_profile_benefits');
    default:
      return undefined;
  }
}

export function profileQuickTagIcon(title: string) {
  switch (title) {
    case '\u76ee\u6807':
      return $r('app.media.icon_profile_goal');
    case '\u6b65\u6570':
      return $r('app.media.icon_exercise_walk');
    case '\u4eca\u65e5\u996e\u98df':
      return $r('app.media.icon_food_bowl');
    case '\u8fd0\u52a8\u6d88\u8017':
      return $r('app.media.icon_exercise_hot');
    default:
      return undefined;
  }
}

export function profilePanelIcon(panel: ProfilePanelType) {
  switch (panel) {
    case 'settings':
      return $r('app.media.icon_ai_spark');
    case 'weekly':
      return $r('app.media.icon_profile_report');
    case 'goal':
      return $r('app.media.icon_profile_goal');
    case 'security':
      return $r('app.media.icon_profile_security');
    case 'feedback':
      return $r('app.media.icon_profile_feedback');
    case 'benefits':
      return $r('app.media.icon_profile_benefits');
    default:
      return $r('app.media.icon_ai_spark');
  }
}

export function profileMenuIcon(id: number) {
  switch (id) {
    case 1:
      return $r('app.media.icon_profile_report');
    case 2:
      return $r('app.media.icon_profile_goal');
    case 3:
      return $r('app.media.icon_profile_security');
    case 4:
      return $r('app.media.icon_profile_feedback');
    default:
      return undefined;
  }
}

export function mealActionIcon(id: number) {
  switch (id) {
    case 1:
      return $r('app.media.icon_meal_breakfast');
    case 2:
      return $r('app.media.icon_meal_lunch');
    case 3:
      return $r('app.media.icon_meal_dinner');
    case 4:
      return $r('app.media.icon_meal_snack');
    case 5:
      return $r('app.media.icon_meal_exercise');
    default:
      return undefined;
  }
}

export function exerciseCategoryIcon(label: string) {
  switch (label) {
    case '\u70ed\u95e8':
      return $r('app.media.icon_exercise_hot');
    case '\u6b65\u884c':
      return $r('app.media.icon_exercise_walk');
    case '\u8dd1\u6b65':
      return $r('app.media.icon_exercise_run');
    case '\u9a91\u884c':
      return $r('app.media.icon_exercise_bike');
    case '\u7403\u7c7b':
      return $r('app.media.icon_exercise_ball');
    case '\u5065\u8eab':
      return $r('app.media.icon_exercise_strength');
    case '\u62c9\u4f38':
      return $r('app.media.icon_exercise_stretch');
    default:
      return undefined;
  }
}

export function mealTypeIcon(type: MealType) {
  switch (type) {
    case 'breakfast':
      return $r('app.media.icon_meal_breakfast');
    case 'lunch':
      return $r('app.media.icon_meal_lunch');
    case 'dinner':
      return $r('app.media.icon_meal_dinner');
    case 'snack':
      return $r('app.media.icon_meal_snack');
    default:
      return $r('app.media.icon_food_bowl');
  }
}
