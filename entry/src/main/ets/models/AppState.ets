export type MealType = 'breakfast' | 'lunch' | 'dinner' | 'snack';
export type AuthMode = 'login' | 'register';

export interface ChatMessage {
  id: number;
  role: 'assistant' | 'user';
  content: string;
  isThinking?: boolean;
}

export interface MealRecordItem {
  id: number;
  mealType: MealType;
  name: string;
  calories: number;
  time: string;
  dayKey: string;
}

export interface ExerciseRecordItem {
  id: number;
  name: string;
  calories: number;
  duration: number;
  category: string;
  time: string;
  dayKey: string;
}

export interface WeightRecordItem {
  id: number;
  value: number;
  time: string;
  dayKey: string;
}

export interface WaterRecordItem {
  id: number;
  amount: number;
  drinkName: string;
  time: string;
  dayKey: string;
}

export interface FavoriteFoodItem {
  id: number;
  name: string;
  calories: number;
  source: string;
  lastUsedAt: string;
}

export interface AppSessionState {
  isAuthenticated: boolean;
  authMode: AuthMode;
  authToken: string;
  authHint: string;
  authProvider: string;
  loginEmail: string;
  needsOnboarding: boolean;
  onboardingName: string;
  onboardingGender: string;
  onboardingAge: string;
  onboardingHeight: string;
  onboardingCurrentWeight: string;
  onboardingTargetWeight: string;
  onboardingWeeklyTarget: string;
}

export interface AppProfileState {
  profileName: string;
  profileEmail: string;
  profileMembership: string;
  profilePoints: number;
  profileGoalText: string;
  profileSignature: string;
  profileNotificationEnabled: boolean;
  profileAiDigestEnabled: boolean;
  profileStepSyncEnabled: boolean;
  profileWaterReminderEnabled: boolean;
  profileReminderTimeDraft: string;
}

export interface AppHealthState {
  activeDayKey: string;
  lastCheckInDayKey: string;
  checkedToday: boolean;
  totalCheckIns: number;
  streakDays: number;
  calories: number;
  breakfastCalories: number;
  lunchCalories: number;
  dinnerCalories: number;
  snackCalories: number;
  water: number;
  waterRecords: WaterRecordItem[];
  steps: number;
  exerciseCaloriesBurned: number;
  stepSyncMessage: string;
  isStepPermissionGranted: boolean;
  isStepSensorReady: boolean;
  weight: number;
  weekLoss: number;
  weightUpdateTime: string;
  scannedImageUri: string;
  lastScannedFood: string;
  lastScannedCalories: number;
  lastScannedSummary: string;
  lastScannedAssignedMeal: string;
  scannedCaloriesTotal: number;
  mealRecords: MealRecordItem[];
  exerciseRecords: ExerciseRecordItem[];
  weightRecords: WeightRecordItem[];
  foodFavorites: FavoriteFoodItem[];
  messages: ChatMessage[];
}

export interface AppPersistentState {
  version: number;
  session: AppSessionState;
  profile: AppProfileState;
  health: AppHealthState;
}

export interface AppRemoteState {
  version: number;
  profile: AppProfileState;
  health: AppHealthState;
}
