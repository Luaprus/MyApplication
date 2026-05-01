import buffer from '@ohos.buffer';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import sensor from '@ohos.sensor';
import { appStateStore } from '../services/AppStateStore';
import { BooheeFoodItem, booheeFoodService } from '../services/BooheeFoodService';
import { DeepSeekMessage, deepSeekService } from '../services/DeepSeekService';
import { FoodRecognitionResult, doubaoVisionService } from '../services/DoubaoVisionService';
import { remoteUserStateService } from '../services/RemoteUserStateService';
import { authService, AuthUser } from '../services/AuthService';
import { AppPersistentState, AppProfileState, AppRemoteState, AppSessionState, AppHealthState, AuthMode, ChatMessage, ExerciseRecordItem, FavoriteFoodItem, MealRecordItem, MealType, WaterRecordItem, WeightRecordItem } from '../models/AppState';
import { ProfileMenuItem, SuggestionItem } from '../models/PageModels';
import { buildWaterCardDisplayStateFromTotal } from '../models/WaterDisplay';
import { mealSearchInputMessage, ProfileQuickTagAction, resolveProfileQuickTagAction } from '../models/InteractionActions';
import { restorePersistedAuthToken, sanitizeSessionForPersistence } from '../models/AuthSessionPersistence';
import { AchievementSummary, buildAchievementSummary, buildGoalAdjustment, buildHealthDataCsv, buildMonthCalendarDayKeys, buildSmartReminders, buildTrendDaySummaries, calculateWeekLoss, deleteFavoriteFood, firstWeightForDay, GoalAdjustment, latestWeightForDay, SmartReminder, TrendDaySummary, updateFavoriteFood, upsertWeightRecordKeepingBaseline } from '../models/FeatureInsights';
import { DrinkPresetItem, ExerciseCategoryItem, ExercisePresetItem, MealActionItem, MealPresetItem, ProfilePanelType, WeeklyWeightPoint } from '../models/IndexModels';
import { EXERCISE_CATEGORIES, EXERCISE_PRESETS, MEAL_ACTIONS, MEAL_PRESETS, PROFILE_MENU_ITEMS, WATER_PRESETS, createDefaultMessages } from '../models/IndexSeedData';
import { healthLightColor, healthLightLabel, mealBgColor, mealDisplayName, mealLabel, mealTint } from '../models/MealDisplay';
import { exerciseCategoryIcon, mealActionIcon, mealTypeIcon, profileMenuIcon, profilePanelIcon, profileQuickTagIcon, profileStatIcon, waterPresetIcon } from '../models/IconResolvers';
import { currentDayKey as currentDateKey, currentWeekDayKeys as weekDayKeys, dateFromDayKey as dateFromKey, dayKeyFromOffset as dayKeyWithOffset, formatClock as currentClockText, monthTitleFromDayKey as monthTitleFromKey } from '../models/DateTimeUtils';
import { clampUnitProgress, clampWeightKg as clampPlanWeightKg, displayWeightDraft as formatWeightDraft, parseWeightPlanWeeklyTarget, progressWidth as formatProgressWidth, weightDraftToKg as parseWeightDraftToKg, weightPlanStartWeight as getWeightPlanStartWeight, weightPlanTargetWeight as getWeightPlanTargetWeight, weightPlanValueLabel as getWeightPlanValueLabel, weightPlanValueText as getWeightPlanValueText, weightPlanWeekNumber as getWeightPlanWeekNumber } from '../models/WeightPlan';
import { exerciseAdjustedCalories as getExerciseAdjustedCalories, exerciseBarHeights as getExerciseBarHeights, exerciseCaloriesForDuration, exerciseDailyAverage as getExerciseDailyAverage, exerciseDurationValue, exerciseGoalDaysThisWeek as getExerciseGoalDaysThisWeek, exerciseOptionsForCategory, exerciseRecordsForDay, exerciseWeekCalories as getExerciseWeekCalories, exerciseWeekLabels as getExerciseWeekLabels, selectedExerciseCalories } from '../models/ExerciseInsights';
import { favoriteFoodRowKey as buildFavoriteFoodRowKey, favoriteFoodRows as buildFavoriteFoodRows, mealPresetRowKey as buildMealPresetRowKey, mealPresetRows as buildMealPresetRows } from '../models/CollectionRows';
import { latestWaterRecord as getLatestWaterRecord, latestWaterRecordForDisplay as getLatestWaterRecordForDisplay, selectedDrinkName as getSelectedDrinkName, waterGoalMl as getWaterGoalMl, waterPresetRows as buildWaterPresetRows, waterProgressPercent as getWaterProgressPercent, waterRecordsForDay } from '../models/WaterInsights';
import { applyMealCaloriesDelta as calculateMealCaloriesDelta, currentMealCaloriesValue as getCurrentMealCaloriesValue, mealCaloriesForType, mealCalorieTotals, MealCalorieTotals, mealRecordsForType } from '../models/MealInsights';
import { goalDisplayText as getGoalDisplayText, goalPlanPreview as getGoalPlanPreview, profileBenefitCount as getProfileBenefitCount, profileHealthScore as getProfileHealthScore, profileInitial as getProfileInitial, profileMenuSubtitle as getProfileMenuSubtitle, weeklyGoalValueText as getWeeklyGoalValueText, weeklyProgressSummary as getWeeklyProgressSummary, weeklySuggestionSummary as getWeeklySuggestionSummary, weightTrendSummary as getWeightTrendSummary } from '../models/ProfileInsights';
import { countMealsForDay, countWaterRecordsForDay, dayRecordDetails as buildDayRecordDetails, trendDayDetailText as buildTrendDayDetailText, weightTextForDay as buildWeightTextForDay } from '../models/TrendDetails';
import { buildDailyCompletionSummary, DailyCompletionItem, DailyCompletionSummary } from '../models/RecordInsights';
import { buildAiSuggestions, WEEKLY_REPORT_LABEL } from '../models/AiSuggestions';
import { AuthModule, OnboardingModule } from './modules/AuthModule';
import { RecordModule } from './modules/RecordModule';
import { AiModule } from './modules/AiModule';
import { ProfileModule } from './modules/ProfileModule';

@Entry
@Component
struct Index {
  private tabsController: TabsController = new TabsController();
  private recordScroller: Scroller = new Scroller();
  private weightArcSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private weightArcContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.weightArcSettings);
  private weeklyWeightChartSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private weeklyWeightChartContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.weeklyWeightChartSettings);
  private readonly activityMotionPermission: Permissions = 'ohos.permission.ACTIVITY_MOTION';
  private readonly demoAccountEmail: string = 'demo@health.app';
  private readonly demoAccountPassword: string = '12345678';
  private isStepSensorListening: boolean = false;
  private persistTimerId: number = -1;
  private remoteSyncTimerId: number = -1;
  private restoreRecordScrollTimerId: number = -1;
  private weightArcRedrawTimerId: number = -1;
  private isRemoteStateBusy: boolean = false;
  private readonly renderQuickAskBar: () => void = () => {
    this.quickAskBar();
  };
  private readonly renderCheckInCard: () => void = () => {
    this.checkInCard();
  };
  private readonly renderWeightPlanCard: () => void = () => {
    this.weightPlanCard();
  };
  private readonly renderCalorieCard: () => void = () => {
    this.calorieCard();
  };
  private readonly renderRecordSection: () => void = () => {
    this.recordSection();
  };
  private readonly renderProfileHeroSection: () => void = () => {
    this.profileHeroSection();
  };
  private readonly renderProfileStatsSection: () => void = () => {
    this.profileStatsSection();
  };
  private readonly renderProfileQuickTagsSection: () => void = () => {
    this.profileQuickTagsSection();
  };
  private readonly renderProfileMenuSection: () => void = () => {
    this.profileMenuSection();
  };
  private readonly renderProfileLogoutSection: () => void = () => {
    this.profileLogoutSection();
  };
  private readonly renderProfileFooterSection: () => void = () => {
    this.profileFooterSection();
  };

  @State isAppStateReady: boolean = false;
  @State isAuthenticated: boolean = false;
  @State isAuthSubmitting: boolean = false;
  @State authMode: AuthMode = 'login';
  @State loginEmail: string = '';
  @State loginPassword: string = '';
  @State registerName: string = '';
  @State registerEmail: string = '';
  @State registerPassword: string = '';
  @State registerConfirmPassword: string = '';
  @State authError: string = '';
  @State authToken: string = '';
  @State authHint: string = '\u53ef\u4ee5\u5148\u6ce8\u518c\u4e00\u4e2a\u8d26\u53f7\uff0c\u4e5f\u53ef\u4ee5\u76f4\u63a5\u767b\u5f55\u6f14\u793a\u8d26\u53f7';
  @State authProvider: string = 'local';
  @State needsOnboarding: boolean = false;
  @State isOnboardingSubmitting: boolean = false;
  @State onboardingError: string = '';
  @State onboardingName: string = '';
  @State onboardingGender: string = '';
  @State onboardingAge: string = '';
  @State onboardingHeight: string = '';
  @State onboardingCurrentWeight: string = '';
  @State onboardingTargetWeight: string = '';
  @State onboardingWeeklyTarget: string = '0.3';
  @State profileName: string = '\u5c0f\u660e';
  @State profileEmail: string = 'demo@health.app';
  @State profilePassword: string = '';
  @State profileMembership: string = '\u767d\u91d1\u4f1a\u5458';
  @State profilePoints: number = 1200;
  @State profileGoalText: string = '\u51cf\u8102 4kg';
  @State profileSignature: string = '\u8fde\u7eed\u8bb0\u5f55 6 \u5929\uff0c\u6b63\u5728\u7a33\u6b65\u63a8\u8fdb';
  @State currentTab: number = 0;
  @State askInput: string = '';
  @State chatInput: string = '';
  @State activeHealthDayKey: string = '';
  @State selectedTrendDayKey: string = '';
  @State lastCheckInDayKey: string = '';
  @State checkedToday: boolean = false;
  @State totalCheckIns: number = 12;
  @State streakDays: number = 6;
  @State isRequesting: boolean = false;
  @State isScanningFood: boolean = false;
  @State isWeightInputOpen: boolean = false;
  @State isWaterSheetOpen: boolean = false;
  @State isMealSheetOpen: boolean = false;
  @State isExerciseSheetOpen: boolean = false;
  @State isExerciseHistoryOpen: boolean = false;
  @State activeProfilePanel: ProfilePanelType = 'none';
  @State profilePanelTitle: string = '';
  @State profileActionMessage: string = '';
  @State profileNameDraft: string = '\u5c0f\u660e';
  @State profileSignatureDraft: string = '\u8fde\u7eed\u8bb0\u5f55 6 \u5929\uff0c\u6b63\u5728\u7a33\u6b65\u63a8\u8fdb';
  @State profileGoalDraft: string = '\u51cf\u8102 4kg';
  @State profileWeeklyTargetDraft: string = '0.3';
  @State profileReminderTimeDraft: string = '21:00';
  @State securityCurrentPasswordDraft: string = '';
  @State securityNextPasswordDraft: string = '';
  @State securityConfirmPasswordDraft: string = '';
  @State feedbackDraft: string = '';
  @State profileNotificationEnabled: boolean = true;
  @State profileAiDigestEnabled: boolean = true;
  @State profileStepSyncEnabled: boolean = true;
  @State profileWaterReminderEnabled: boolean = false;
  @State showWeightRuler: boolean = false;
  @State foodScanStatus: string = 'AI \u89c6\u89c9\u8bc6\u522b\u4e2d...';
  @State calories: number = 0;
  @State breakfastCalories: number = 0;
  @State lunchCalories: number = 0;
  @State dinnerCalories: number = 0;
  @State snackCalories: number = 0;
  @State water: number = 1250;
  @State waterSheetTime: string = '13:47';
  @State waterDraft: string = '350';
  @State selectedDrinkId: number = 1;
  @State waterInputError: string = '';
  @State waterCardValueText: string = '0 ml';
  @State waterCardSubtitleText: string = '';
  @State waterCardActionText: string = '\u53bb\u8bb0\u5f55';
  @State recordRenderEpoch: number = 0;
  @State recordScrollOffset: number = 0;
  @State steps: number = 0;
  @State exerciseCaloriesBurned: number = 0;
  @State stepSyncMessage: string = '\u5b9e\u673a\u540e\u81ea\u52a8\u540c\u6b65\u6b65\u6570';
  @State isStepPermissionGranted: boolean = false;
  @State isStepSensorReady: boolean = false;
  @State weight: number = 61.90;
  @State weekLoss: number = 0.10;
  @State weightUpdateTime: string = '14:59';
  @State weightInputTime: string = '14:59';
  @State weightDraft: string = '61.90';
  @State weightDraftUnit: 'kg' | 'jin' = 'kg';
  @State weightInputError: string = '';
  @State scannedImageUri: string = '';
  @State lastScannedFood: string = '';
  @State lastScannedCalories: number = 0;
  @State lastScannedSummary: string = '';
  @State lastScannedAssignedMeal: string = '';
  @State scannedCaloriesTotal: number = 0;
  @State activeMealType: MealType = 'breakfast';
  @State mealSheetTime: string = '08:30';
  @State mealSearchKeyword: string = '';
  @State isMealSearching: boolean = false;
  @State mealSearchError: string = '';
  @State mealSearchResults: BooheeFoodItem[] = [];
  @State foodFavorites: FavoriteFoodItem[] = [];
  @State dataExportPreview: string = '';
  @State manualFoodNameDraft: string = '';
  @State manualFoodCaloriesDraft: string = '';
  @State manualFoodError: string = '';
  @State editingFavoriteId: number = -1;
  @State favoriteEditNameDraft: string = '';
  @State favoriteEditCaloriesDraft: string = '';
  @State favoriteEditMessage: string = '';
  @State mealRecords: MealRecordItem[] = [];
  @State activeExerciseCategory: string = '\u70ed\u95e8';
  @State exerciseSearchKeyword: string = '';
  @State selectedExerciseId: number = -1;
  @State exerciseDurationDraft: string = '';
  @State exerciseSheetTime: string = '20:30';
  @State exerciseRecords: ExerciseRecordItem[] = [];
  @State waterRecords: WaterRecordItem[] = [];
  @State weightRecords: WeightRecordItem[] = [];
  @State messages: ChatMessage[] = createDefaultMessages();

  private profileMenuItems: ProfileMenuItem[] = PROFILE_MENU_ITEMS;
  private mealActions: MealActionItem[] = MEAL_ACTIONS;
  private mealPresets: MealPresetItem[] = MEAL_PRESETS;
  private exerciseCategories: ExerciseCategoryItem[] = EXERCISE_CATEGORIES;
  private exercisePresets: ExercisePresetItem[] = EXERCISE_PRESETS;
  private waterPresets: DrinkPresetItem[] = WATER_PRESETS;

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (!this.isAppStateReady) {
        this.appLoadingPage();
      } else if (!this.isAuthenticated) {
        AuthModule({
          authMode: this.$authMode,
          loginEmail: this.$loginEmail,
          loginPassword: this.$loginPassword,
          registerName: this.$registerName,
          registerEmail: this.$registerEmail,
          registerPassword: this.$registerPassword,
          registerConfirmPassword: this.$registerConfirmPassword,
          authError: this.$authError,
          isAuthSubmitting: this.isAuthSubmitting,
          authHint: this.authHint,
          onSwitchAuthMode: (mode: AuthMode) => {
            this.switchAuthMode(mode);
          },
          onUseDemoAccount: () => {
            this.useDemoAccount();
          },
          onSubmitLogin: () => {
            void this.submitLogin();
          },
          onSubmitRegister: () => {
            void this.submitRegister();
          }
        })
      } else if (this.needsOnboarding) {
        OnboardingModule({
          onboardingName: this.$onboardingName,
          onboardingGender: this.$onboardingGender,
          onboardingAge: this.$onboardingAge,
          onboardingHeight: this.$onboardingHeight,
          onboardingCurrentWeight: this.$onboardingCurrentWeight,
          onboardingTargetWeight: this.$onboardingTargetWeight,
          onboardingWeeklyTarget: this.$onboardingWeeklyTarget,
          onboardingError: this.$onboardingError,
          isOnboardingSubmitting: this.isOnboardingSubmitting,
          onSubmit: () => {
            void this.submitOnboarding();
          }
        })
      } else {
        Stack({ alignContent: Alignment.Bottom }) {
          Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
            TabContent() {
              Column() {
                ForEach([this.recordRenderEpoch], (epoch: number) => {
                  RecordModule({
                    quickAskBuilder: this.renderQuickAskBar,
                    checkInBuilder: this.renderCheckInCard,
                    weightPlanBuilder: this.renderWeightPlanCard,
                    calorieBuilder: this.renderCalorieCard,
                    recordSectionBuilder: this.renderRecordSection,
                    scroller: this.recordScroller,
                    waterValue: this.$waterCardValueText,
                    waterSubtitle: this.$waterCardSubtitleText,
                    waterButtonText: this.$waterCardActionText,
                    stepValue: this.stepDisplayText(),
                    stepSubtitle: this.stepSyncMessage,
                    stepButtonText: this.stepButtonText(),
                    onWaterClick: () => {
                      this.openWaterSheet();
                    },
                    onStepClick: () => {
                      this.refreshDeviceSteps();
                    },
                    onScrollPositionChange: (yOffset: number) => {
                      this.recordScrollOffset = Math.max(0, yOffset);
                    }
                  })
                }, (epoch: number) => epoch.toString())
              }
              .width('100%')
              .height('100%')
            }.tabBar(this.tabItem('\u8bb0\u5f55', 0))

            TabContent() {
              AiModule({
                chatInput: this.$chatInput,
                isRequesting: this.isRequesting,
                messages: this.messages,
                suggestions: this.aiSuggestions(),
                onSuggestionSelect: (label: string) => {
                  this.sendSuggestedQuestion(label);
                },
                onSend: () => {
                  this.sendCurrentMessage();
                },
                onClearHistory: () => {
                  this.clearAiConversation();
                }
              })
            }.tabBar(this.tabItem('AI', 1))

            TabContent() {
              ProfileModule({
                heroBuilder: this.renderProfileHeroSection,
                statsBuilder: this.renderProfileStatsSection,
                tagsBuilder: this.renderProfileQuickTagsSection,
                menuBuilder: this.renderProfileMenuSection,
                logoutBuilder: this.renderProfileLogoutSection,
                footerBuilder: this.renderProfileFooterSection
              })
            }.tabBar(this.tabItem('\u6211\u7684', 2))
          }
          .barMode(BarMode.Fixed)
          .animationDuration(220)
          .scrollable(false)
          .backgroundColor('#F8FAFC')
          .onChange((index: number) => {
            this.currentTab = index;
          })

          if (this.isScanningFood) {
            this.foodScanOverlay();
          }

          if (this.isWeightInputOpen) {
            this.weightInputSheet();
          }

          if (this.isWaterSheetOpen) {
            this.waterRecordSheet();
          }

          if (this.isMealSheetOpen) {
            this.mealRecordSheet();
          }

          if (this.isExerciseSheetOpen) {
            this.exerciseRecordSheet();
          }

          if (this.isExerciseHistoryOpen) {
            this.exerciseHistorySheet();
          }

          if (this.activeProfilePanel !== 'none') {
            this.profileDetailSheet();
          }
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
  }

  aboutToAppear(): void {
    void this.initializeApp();
  }

  aboutToDisappear(): void {
    this.clearPersistTimer();
    this.clearRemoteSyncTimer();
    this.clearRestoreRecordScrollTimer();
    this.clearWeightArcRedrawTimer();
    void this.persistAppState();
    void this.syncRemoteStateToServer();
    this.stopStepSync();
  }

  async initializeApp(): Promise<void> {
    if (!this.isAppStateReady) {
      await this.restoreAppState();
      this.isAppStateReady = true;
    }
    this.ensureDailyHealthStateCurrent();
    await this.restoreRemoteStateIfNeeded();
    void this.startStepSync();
  }

  async restoreAppState(): Promise<void> {
    let context: common.Context | undefined = this.getHostContext();
    if (context === undefined) {
      return;
    }

    try {
      let savedState: AppPersistentState | null = await appStateStore.load(context);
      if (savedState === null) {
        this.weightRecords = [this.createWeightRecord(this.weight, this.weightUpdateTime, this.currentDayKey())];
        this.activeHealthDayKey = this.currentDayKey();
        return;
      }
      this.applyPersistentState(savedState);
      this.finalizeRestoredHealthState();
      if (this.weightRecords.length === 0) {
        this.weightRecords = [this.createWeightRecord(this.weight, this.weightUpdateTime, this.currentDayKey())];
      }
    } catch (error) {
      this.weightRecords = [this.createWeightRecord(this.weight, this.weightUpdateTime, this.currentDayKey())];
      this.activeHealthDayKey = this.currentDayKey();
    }
  }

  applyPersistentState(state: AppPersistentState): void {
    let session: AppSessionState = state.session;
    let profile: AppProfileState = state.profile;
    let health: AppHealthState = state.health;

    this.isAuthenticated = session.isAuthenticated;
    this.authMode = session.authMode;
    this.authToken = restorePersistedAuthToken(session);
    this.authHint = session.authHint;
    this.authProvider = session.authProvider;
    this.loginEmail = session.loginEmail;
    this.needsOnboarding = session.needsOnboarding;
    this.onboardingName = session.onboardingName;
    this.onboardingGender = session.onboardingGender;
    this.onboardingAge = session.onboardingAge;
    this.onboardingHeight = session.onboardingHeight;
    this.onboardingCurrentWeight = session.onboardingCurrentWeight;
    this.onboardingTargetWeight = session.onboardingTargetWeight;
    this.onboardingWeeklyTarget = session.onboardingWeeklyTarget;

    this.profileName = profile.profileName;
    this.profileEmail = profile.profileEmail;
    this.profileMembership = profile.profileMembership;
    this.profilePoints = profile.profilePoints;
    this.profileGoalText = profile.profileGoalText;
    this.profileSignature = profile.profileSignature;
    this.profileNameDraft = profile.profileName;
    this.profileGoalDraft = profile.profileGoalText;
    this.profileSignatureDraft = profile.profileSignature;
    this.profileNotificationEnabled = profile.profileNotificationEnabled ?? true;
    this.profileAiDigestEnabled = profile.profileAiDigestEnabled ?? true;
    this.profileStepSyncEnabled = profile.profileStepSyncEnabled ?? true;
    this.profileWaterReminderEnabled = profile.profileWaterReminderEnabled ?? false;
    this.profileReminderTimeDraft = profile.profileReminderTimeDraft || '21:00';

    this.activeHealthDayKey = health.activeDayKey || this.currentDayKey();
    this.selectedTrendDayKey = this.activeHealthDayKey;
    this.lastCheckInDayKey = health.lastCheckInDayKey
      || (health.checkedToday ? this.activeHealthDayKey : '');
    this.checkedToday = health.checkedToday;
    this.totalCheckIns = health.totalCheckIns;
    this.streakDays = health.streakDays;
    this.calories = health.calories;
    this.breakfastCalories = health.breakfastCalories;
    this.lunchCalories = health.lunchCalories;
    this.dinnerCalories = health.dinnerCalories;
    this.snackCalories = health.snackCalories;
    this.water = health.water;
    this.waterRecords = Array.isArray(health.waterRecords) ? health.waterRecords : [];
    this.steps = health.steps;
    this.exerciseCaloriesBurned = health.exerciseCaloriesBurned;
    this.stepSyncMessage = health.stepSyncMessage;
    this.isStepPermissionGranted = health.isStepPermissionGranted;
    this.isStepSensorReady = health.isStepSensorReady;
    this.weight = health.weight;
    this.weekLoss = health.weekLoss;
    this.weightUpdateTime = health.weightUpdateTime;
    this.weightDraft = health.weight.toFixed(2);
    this.weightInputTime = health.weightUpdateTime;
    this.scannedImageUri = health.scannedImageUri;
    this.lastScannedFood = health.lastScannedFood;
    this.lastScannedCalories = health.lastScannedCalories;
    this.lastScannedSummary = health.lastScannedSummary;
    this.lastScannedAssignedMeal = health.lastScannedAssignedMeal;
    this.scannedCaloriesTotal = health.scannedCaloriesTotal;
    this.mealRecords = this.normalizeMealRecords(
      Array.isArray(health.mealRecords) ? health.mealRecords : [],
      this.activeHealthDayKey
    );
    this.exerciseRecords = Array.isArray(health.exerciseRecords) ? health.exerciseRecords : [];
    this.weightRecords = Array.isArray(health.weightRecords) ? health.weightRecords : [];
    this.foodFavorites = Array.isArray(health.foodFavorites) ? health.foodFavorites : [];
    this.messages = Array.isArray(health.messages) && health.messages.length > 0 ? health.messages : this.messages;
  }

  capturePersistentState(): AppPersistentState {
    return {
      version: 3,
      session: sanitizeSessionForPersistence({
        isAuthenticated: this.isAuthenticated,
        authMode: this.authMode,
        authToken: this.authToken,
        authHint: this.authHint,
        authProvider: this.authProvider,
        loginEmail: this.loginEmail,
        needsOnboarding: this.needsOnboarding,
        onboardingName: this.onboardingName,
        onboardingGender: this.onboardingGender,
        onboardingAge: this.onboardingAge,
        onboardingHeight: this.onboardingHeight,
        onboardingCurrentWeight: this.onboardingCurrentWeight,
        onboardingTargetWeight: this.onboardingTargetWeight,
        onboardingWeeklyTarget: this.onboardingWeeklyTarget
      }),
      profile: {
        profileName: this.profileName,
        profileEmail: this.profileEmail,
        profileMembership: this.profileMembership,
        profilePoints: this.profilePoints,
        profileGoalText: this.profileGoalText,
        profileSignature: this.profileSignature,
        profileNotificationEnabled: this.profileNotificationEnabled,
        profileAiDigestEnabled: this.profileAiDigestEnabled,
        profileStepSyncEnabled: this.profileStepSyncEnabled,
        profileWaterReminderEnabled: this.profileWaterReminderEnabled,
        profileReminderTimeDraft: this.profileReminderTimeDraft
      },
      health: {
        activeDayKey: this.activeHealthDayKey,
        lastCheckInDayKey: this.lastCheckInDayKey,
        checkedToday: this.checkedToday,
        totalCheckIns: this.totalCheckIns,
        streakDays: this.streakDays,
        calories: this.calories,
        breakfastCalories: this.breakfastCalories,
        lunchCalories: this.lunchCalories,
        dinnerCalories: this.dinnerCalories,
        snackCalories: this.snackCalories,
        water: this.water,
        waterRecords: this.waterRecords,
        steps: this.steps,
        exerciseCaloriesBurned: this.exerciseCaloriesBurned,
        stepSyncMessage: this.stepSyncMessage,
        isStepPermissionGranted: this.isStepPermissionGranted,
        isStepSensorReady: this.isStepSensorReady,
        weight: this.weight,
        weekLoss: this.weekLoss,
        weightUpdateTime: this.weightUpdateTime,
        scannedImageUri: this.scannedImageUri,
        lastScannedFood: this.lastScannedFood,
        lastScannedCalories: this.lastScannedCalories,
        lastScannedSummary: this.lastScannedSummary,
        lastScannedAssignedMeal: this.lastScannedAssignedMeal,
        scannedCaloriesTotal: this.scannedCaloriesTotal,
        mealRecords: this.mealRecords,
        exerciseRecords: this.exerciseRecords,
        weightRecords: this.weightRecords,
        foodFavorites: this.foodFavorites,
        messages: this.messagesForModel(this.messages)
      }
    };
  }

  captureRemoteState(): AppRemoteState {
    let persistentState: AppPersistentState = this.capturePersistentState();
    return {
      version: persistentState.version,
      profile: persistentState.profile,
      health: persistentState.health
    };
  }

  applyRemoteState(state: AppRemoteState): void {
    let localState: AppPersistentState = this.capturePersistentState();
    this.applyPersistentState({
      version: state.version,
      session: localState.session,
      profile: state.profile,
      health: state.health
    });
  }

  normalizeMealRecords(records: MealRecordItem[], fallbackDayKey: string): MealRecordItem[] {
    let normalized: MealRecordItem[] = [];
    let safeDayKey: string = fallbackDayKey.length > 0 ? fallbackDayKey : this.currentDayKey();
    for (let index = 0; index < records.length; index++) {
      let item: MealRecordItem = records[index];
      normalized.push({
        id: item.id,
        mealType: item.mealType,
        name: item.name,
        calories: item.calories,
        time: item.time,
        dayKey: typeof item.dayKey === 'string' && item.dayKey.length > 0 ? item.dayKey : safeDayKey
      });
    }
    return normalized;
  }

  finalizeRestoredHealthState(): void {
    this.ensureDailyHealthStateCurrent();
    this.syncWaterIntake();
    this.syncCalories(this.mealRecords);
    this.syncExerciseCaloriesBurned();
    this.recalculateWeightMetrics();
    this.messages = this.messagesForModel(this.messages);
  }

  ensureDailyHealthStateCurrent(): void {
    let todayKey: string = this.currentDayKey();
    if (this.activeHealthDayKey.length === 0) {
      this.activeHealthDayKey = todayKey;
    }

    if (this.activeHealthDayKey !== todayKey) {
      this.activeHealthDayKey = todayKey;
      this.checkedToday = false;
      this.water = 0;
      this.steps = 0;
      this.scannedImageUri = '';
      this.lastScannedFood = '';
      this.lastScannedCalories = 0;
      this.lastScannedSummary = '';
      this.lastScannedAssignedMeal = '';
      this.scannedCaloriesTotal = 0;
      if (this.isStepSensorReady) {
        this.stepSyncMessage = '\u65b0\u7684\u4e00\u5929\uff0c\u70b9\u51fb\u5237\u65b0\u6b65\u6570';
      }
      this.syncCalories(this.mealRecords);
      this.syncExerciseCaloriesBurned();
    }

    this.syncWaterIntake();
    this.checkedToday = this.lastCheckInDayKey === todayKey;
  }

  queuePersistAppState(): void {
    if (!this.isAppStateReady) {
      return;
    }

    this.clearPersistTimer();
    this.persistTimerId = setTimeout(() => {
      void this.persistAppState();
    }, 400);
    this.queueRemoteStateSync();
  }

  clearPersistTimer(): void {
    if (this.persistTimerId >= 0) {
      clearTimeout(this.persistTimerId);
      this.persistTimerId = -1;
    }
  }

  shouldSyncRemoteState(): boolean {
    return this.isAppStateReady
      && this.isAuthenticated
      && !this.needsOnboarding
      && this.authToken.trim().length > 0
      && this.authToken !== 'offline-demo-token';
  }

  queueRemoteStateSync(): void {
    if (!this.shouldSyncRemoteState()) {
      return;
    }

    this.clearRemoteSyncTimer();
    this.remoteSyncTimerId = setTimeout(() => {
      void this.syncRemoteStateToServer();
    }, 900);
  }

  clearRemoteSyncTimer(): void {
    if (this.remoteSyncTimerId >= 0) {
      clearTimeout(this.remoteSyncTimerId);
      this.remoteSyncTimerId = -1;
    }
  }

  clearRestoreRecordScrollTimer(): void {
    if (this.restoreRecordScrollTimerId >= 0) {
      clearTimeout(this.restoreRecordScrollTimerId);
      this.restoreRecordScrollTimerId = -1;
    }
  }

  clearWeightArcRedrawTimer(): void {
    if (this.weightArcRedrawTimerId >= 0) {
      clearTimeout(this.weightArcRedrawTimerId);
      this.weightArcRedrawTimerId = -1;
    }
  }

  captureRecordScrollOffset(): void {
    try {
      let currentOffset = this.recordScroller.currentOffset();
      this.recordScrollOffset = Math.max(0, currentOffset.yOffset);
    } catch (error) {
    }
  }

  scheduleRecordScrollRestore(): void {
    this.clearRestoreRecordScrollTimer();
    let targetOffset: number = this.recordScrollOffset;
    this.restoreRecordScrollTimerId = setTimeout(() => {
      this.restoreRecordScrollTimerId = -1;
      try {
        this.recordScroller.scrollTo({
          xOffset: 0,
          yOffset: targetOffset,
          animation: {
            duration: 0
          }
        });
      } catch (error) {
      }
    }, 60);
  }

  refreshRecordModuleKeepingScroll(): void {
    this.captureRecordScrollOffset();
    this.recordRenderEpoch += 1;
    this.scheduleRecordScrollRestore();
    this.scheduleWeightArcRedraw();
  }

  scheduleWeightArcRedraw(): void {
    this.clearWeightArcRedrawTimer();
    this.weightArcRedrawTimerId = setTimeout(() => {
      this.weightArcRedrawTimerId = -1;
      this.drawWeightArc();
    }, 90);
  }

  async persistAppState(): Promise<void> {
    if (!this.isAppStateReady) {
      return;
    }

    let context: common.Context | undefined = this.getHostContext();
    if (context === undefined) {
      return;
    }

    try {
      await appStateStore.save(context, this.capturePersistentState());
    } catch (error) {
    }
  }

  async restoreRemoteStateIfNeeded(): Promise<void> {
    if (!this.shouldSyncRemoteState() || this.isRemoteStateBusy) {
      return;
    }

    this.isRemoteStateBusy = true;
    try {
      let remoteState: AppRemoteState | null = await remoteUserStateService.fetch(this.authToken);
      if (remoteState === null) {
        await remoteUserStateService.save(this.authToken, this.captureRemoteState());
        return;
      }

      this.applyRemoteState(remoteState);
      this.finalizeRestoredHealthState();
      if (this.weightRecords.length === 0) {
        this.weightRecords = [this.createWeightRecord(this.weight, this.weightUpdateTime, this.currentDayKey())];
      }
      await this.persistAppState();
    } catch (error) {
    } finally {
      this.isRemoteStateBusy = false;
    }
  }

  async syncRemoteStateToServer(): Promise<void> {
    if (!this.shouldSyncRemoteState() || this.isRemoteStateBusy) {
      return;
    }

    this.clearRemoteSyncTimer();
    this.isRemoteStateBusy = true;
    try {
      await remoteUserStateService.save(this.authToken, this.captureRemoteState());
    } catch (error) {
    } finally {
      this.isRemoteStateBusy = false;
    }
  }

  @Builder
  tabItem(title: string, index: number) {
    Column({ space: 4 }) {
      if (index === 0) {
        Image(this.currentTab === index ? $r('app.media.tab_home_active') : $r('app.media.tab_home_inactive'))
          .width(27)
          .height(27)
      } else if (index === 1) {
        Image(this.currentTab === index ? $r('app.media.tab_ai_active') : $r('app.media.tab_ai_inactive'))
          .width(27)
          .height(27)
      } else {
        this.profileTabIcon(this.currentTab === index)
      }

      Text(title)
        .fontSize(12)
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.currentTab === index ? '#36C79A' : '#7B8797')
    }
    .padding({ top: 8, bottom: 8 })
    .width('100%')
  }

  @Builder
  profileTabIcon(active: boolean) {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(11)
        .height(11)
        .borderRadius(5.5)
        .backgroundColor(active ? '#36C79A' : '#7B8797')
        .margin({ bottom: 12 })

      Column()
        .width(19)
        .height(10)
        .borderRadius({ topLeft: 6, topRight: 6, bottomLeft: 5, bottomRight: 5 })
        .backgroundColor(active ? '#36C79A' : '#7B8797')
    }
    .width(27)
    .height(27)
  }

  @Builder
  appLoadingPage() {
    Column({ space: 14 }) {
      LoadingProgress()
        .width(30)
        .height(30)
        .color('#36C79A')

      Text('\u6b63\u5728\u6062\u590d\u4f60\u7684\u6570\u636e...')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#607184')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  authInputCard(title: string, placeholder: string, value: string, onChange: (value: string) => void) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#607184')

      TextInput({ text: value, placeholder: placeholder })
        .width('100%')
        .height(52)
        .fontSize(15)
        .fontColor('#0F172A')
        .backgroundColor('#F8FAFC')
        .borderRadius(18)
        .padding({ left: 16, right: 16 })
        .onChange((nextValue: string) => {
          onChange(nextValue);
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  quickAskBar() {
    Column({ space: 14 }) {
      Row() {
        Row({ space: 10 }) {
          Row() {
            Image($r('app.media.icon_ai_spark'))
              .width(30)
              .height(30)
              .objectFit(ImageFit.Contain)
          }
          .width(44)
          .height(44)
          .borderRadius(16)
          .backgroundColor('#ECFBF5')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)

          Column({ space: 3 }) {
            Text('\u4eca\u5929\u4e5f\u6162\u6162\u6765')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F172A')

            Text(this.checkedToday ? '\u6253\u5361\u5df2\u5b8c\u6210\uff0c\u72b6\u6001\u6b63\u5728\u7a33\u4f4f' : '\u5148\u8bb0\u4e00\u7b14\uff0c\u8282\u594f\u5c31\u56de\u6765\u4e86')
              .fontSize(12)
              .fontColor('#64748B')
          }
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)

        Text('AI')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#36C79A')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor('#F2FCF9')
          .borderRadius(14)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row({ space: 8 }) {
        TextInput({ text: this.askInput, placeholder: '\u95ee\u95ee AI\uff1a\u7761\u7720\u5982\u4f55\u5f71\u54cd\u4f53\u91cd\uff1f' })
          .layoutWeight(1)
          .height(42)
          .fontSize(15)
          .fontColor('#1F2937')
          .backgroundColor('#FFFFFF')
          .borderRadius(21)
          .padding({ left: 16, right: 8 })
          .onChange((value: string) => {
            this.askInput = value;
          })

        Button() {
          Image($r('app.media.icon_send_arrow'))
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
            .opacity(this.askInput.trim().length > 0 && !this.isRequesting ? 1 : 0.55)
        }
          .width(42)
          .height(42)
          .backgroundColor(this.askInput.trim().length > 0 && !this.isRequesting ? '#36C79A' : '#B7C2D1')
          .borderRadius(21)
          .padding(0)
          .onClick(() => {
            this.sendFromQuickAsk();
          })
      }
      .width('100%')
    }
    .padding(16)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
  }

  @Builder
  checkInCard() {
    Column() {
      Row() {
        Row() {
          Image($r('app.media.icon_checkin_streak'))
            .width(30)
            .height(30)
            .objectFit(ImageFit.Contain)
        }
        .width(44)
        .height(44)
        .borderRadius(16)
        .backgroundColor('#FFFFFF99')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        this.statPill('\u7d2f\u8ba1\u6253\u5361', `${this.totalCheckIns}`, '\u5929')
        this.statPill('\u8fde\u7eed\u6253\u5361', `${this.streakDays}`, '\u5929')
      }
      .padding(16)
      .width('100%')
      .linearGradient({
        angle: 90,
        colors: [['#B9F2E3', 0.0], ['#C7FCEB', 1.0]]
      })
      .borderRadius({ topLeft: 24, topRight: 24, bottomLeft: 0, bottomRight: 0 })
      .justifyContent(FlexAlign.SpaceBetween)

      Row() {
        Text(this.checkedToday ? '\u4eca\u65e5\u5df2\u5b8c\u6210\u6253\u5361\uff0c\u7ee7\u7eed\u4fdd\u6301\u3002' : '\u5168\u529b\u4ee5\u8d74\uff0c\u4f60\u4f1a\u8d8a\u6765\u8d8a\u8f7b\u76c8\u3002')
          .fontSize(14)
          .fontColor('#64748B')

        if (!this.checkedToday) {
          Button('\u7acb\u5373\u6253\u5361')
            .height(36)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .backgroundColor('#36C79A')
            .borderRadius(18)
            .onClick(() => {
              this.checkIn();
            })
        } else {
          Text('\u5df2\u5b8c\u6210')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#36C79A')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor('#ECFBF5')
            .borderRadius(16)
        }
      }
      .padding(16)
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 0, topRight: 0, bottomLeft: 24, bottomRight: 24 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
  }

  @Builder
  statPill(title: string, value: string, unit: string) {
    Row({ space: 4 }) {
      Text(title)
        .fontSize(13)
        .fontColor('#334155')

      Text(value)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0F172A')

      Text(unit)
        .fontSize(13)
        .fontColor('#334155')
    }
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor('#66FFFFFF')
    .borderRadius(18)
  }

  @Builder
  weightPlanCard() {
    Column({ space: 18 }) {
      Row() {
        Row({ space: 8 }) {
          Image($r('app.media.icon_weight_scale'))
            .width(24)
            .height(24)
            .objectFit(ImageFit.Contain)

          Text('\u4f53\u91cd\u7ba1\u7406\u65b9\u6848')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0F172A')

          Text('\u67e5\u770b')
            .fontSize(12)
            .fontColor('#36C79A')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#ECFBF5')
            .borderRadius(12)
            .onClick(() => {
              this.openProfilePanel('goal');
            })
        }

        Row({ space: 6 }) {
          Text('\u7b2c')
            .fontSize(13)
            .fontColor('#70819A')

          Text(`${this.weightPlanWeekNumber()}`)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#36C79A')
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .backgroundColor('#ECFBF5')
            .borderRadius(12)

          Text('\u5468')
            .fontSize(13)
            .fontColor('#70819A')
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Column({ space: 10 }) {
        this.weightArcGauge()
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      Row() {
        this.weightAnchor(this.weightPlanStartWeight().toFixed(2), '\u521d\u59cb')
        this.weightAnchor(`${this.weight.toFixed(2)}`, '\u5f53\u524d')
        this.weightAnchor(this.weightPlanTargetWeight().toFixed(2), '\u76ee\u6807')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .padding(20)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .onClick(() => {
      this.openProfilePanel('goal');
    })
  }

  @Builder
  weightAnchor(value: string, title: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0F172A')

      Text(title)
        .fontSize(12)
        .fontColor('#94A3B8')
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  calorieCard() {
    Column({ space: 18 }) {
      Row() {
        Row({ space: 8 }) {
          Image($r('app.media.icon_food_bowl'))
            .width(24)
            .height(24)
            .objectFit(ImageFit.Contain)

          Text('\u996e\u98df\u70ed\u91cf')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0F172A')
        }
        .alignItems(VerticalAlign.Center)

        Row({ space: 4 }) {
          this.dot('#D7DEE8')
          this.dot('#36C79A')
          this.dot('#D7DEE8')
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Row({ space: 12 }) {
        Column({ space: 6 }) {
          Text('\u8fd8\u53ef\u5403')
            .fontSize(12)
            .fontColor('#607184')

          Row({ space: 2 }) {
            Text(`${Math.max(0, 1791 - this.calories)}`)
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F172A')

            Text('\u5343\u5361')
              .fontSize(12)
              .fontColor('#94A3B8')
              .margin({ top: 10 })
          }
        }
        .layoutWeight(1)
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .alignItems(HorizontalAlign.Start)

        Column({ space: 6 }) {
          Text('\u996e\u98df')
            .fontSize(12)
            .fontColor('#607184')

          Text(`${this.calories}`)
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor('#36C79A')
        }
        .layoutWeight(1)
        .padding(16)
        .backgroundColor('#F2FCF9')
        .borderRadius(18)
        .alignItems(HorizontalAlign.Start)

        Column({ space: 6 }) {
          Text('\u8fd0\u52a8*0.9')
            .fontSize(12)
            .fontColor('#607184')

          Text(`${this.exerciseAdjustedCalories()}`)
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF9D4D')
        }
        .layoutWeight(1)
        .padding(16)
        .backgroundColor('#FFF7EE')
        .borderRadius(18)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Row() {
        ForEach(this.mealActions, (item: MealActionItem) => {
          this.foodAction(item)
        }, (item: MealActionItem) => item.id.toString())
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Row({ space: 10 }) {
        Column({ space: 4 }) {
          Text('\u65e9\u9910')
            .fontSize(12)
            .fontColor('#607184')

          Text(`${this.breakfastCalories} \u5343\u5361`)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF9D4D')
        }
        .layoutWeight(1)
        .padding({ top: 10, bottom: 10 })
        .backgroundColor('#FFF7EE')
        .borderRadius(16)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.openMealSheet('breakfast');
        })

        Column({ space: 4 }) {
          Text('\u5348\u9910')
            .fontSize(12)
            .fontColor('#607184')

          Text(`${this.lunchCalories} \u5343\u5361`)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4B8DFF')
        }
        .layoutWeight(1)
        .padding({ top: 10, bottom: 10 })
        .backgroundColor('#EEF4FF')
        .borderRadius(16)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.openMealSheet('lunch');
        })

        Column({ space: 4 }) {
          Text('\u665a\u9910')
            .fontSize(12)
            .fontColor('#607184')

          Text(`${this.dinnerCalories} \u5343\u5361`)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#8B5CF6')
        }
        .layoutWeight(1)
        .padding({ top: 10, bottom: 10 })
        .backgroundColor('#F4EEFF')
        .borderRadius(16)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.openMealSheet('dinner');
        })
      }
      .width('100%')

      Button() {
        Row({ space: 8 }) {
          Image($r('app.media.icon_camera_scan'))
            .width(22)
            .height(22)
            .objectFit(ImageFit.Contain)

          Text('\u62cd\u7167\u8bc6\u522b\u98df\u7269\u70ed\u91cf')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#36C79A')
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
      }
        .width('100%')
        .height(46)
        .backgroundColor('#F2FCF9')
        .borderRadius(23)
        .onClick(() => {
          this.startFoodScan();
        })

      if (this.lastScannedFood.length > 0) {
        Column({ space: 12 }) {
          Row({ space: 12 }) {
            if (this.scannedImageUri.length > 0) {
              Image(this.scannedImageUri)
                .width(58)
                .height(58)
                .borderRadius(16)
                .objectFit(ImageFit.Cover)
            }

            Column({ space: 4 }) {
              Text(this.lastScannedFood)
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#0F172A')
              Text(`+\u0020${this.lastScannedCalories}\u0020\u5343\u5361`)
                .fontSize(12)
                .fontColor('#64748B')
              Text(this.lastScannedSummary)
                .fontSize(11)
                .lineHeight(16)
                .fontColor('#94A3B8')
                .maxLines(2)
            }
            .layoutWeight(1)

            Text('\u521a\u521a\u62cd\u7167')
              .fontSize(12)
              .fontColor('#36C79A')
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor('#ECFBF5')
              .borderRadius(14)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)

          if (this.lastScannedCalories > 0) {
            Row({ space: 8 }) {
              Button('-50')
                .layoutWeight(1)
                .height(34)
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor('#F97316')
                .backgroundColor('#FFF3EA')
                .borderRadius(14)
                .onClick(() => {
                  this.adjustScannedCalories(-50);
                })

              Button('+50')
                .layoutWeight(1)
                .height(34)
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor('#36C79A')
                .backgroundColor('#ECFBF5')
                .borderRadius(14)
                .onClick(() => {
                  this.adjustScannedCalories(50);
                })

              Button('\u6536\u85cf')
                .layoutWeight(1)
                .height(34)
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor('#4B8DFF')
                .backgroundColor('#EEF4FF')
                .borderRadius(14)
                .onClick(() => {
                  this.addFavoriteFood(this.lastScannedFood, this.lastScannedCalories, 'AI \u8bc6\u522b');
                })
            }
            .width('100%')
          }

          if (this.lastScannedCalories > 0 && this.lastScannedAssignedMeal.length === 0) {
            Column({ space: 8 }) {
              Text('\u6dfb\u52a0\u5230')
                .fontSize(12)
                .fontColor('#94A3B8')

              Row({ space: 8 }) {
                this.scannedMealButton('\u65e9\u9910', 'breakfast', '#FFF7EE', '#FF9D4D')
                this.scannedMealButton('\u5348\u9910', 'lunch', '#EEF4FF', '#4B8DFF')
                this.scannedMealButton('\u665a\u9910', 'dinner', '#F4EEFF', '#8B5CF6')
                this.scannedMealButton('\u52a0\u9910', 'snack', '#FFF3EA', '#F97316')
              }
              .width('100%')
            }
            .width('100%')
          }

          if (this.lastScannedAssignedMeal.length > 0) {
            Text(this.lastScannedAssignedMeal)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor('#36C79A')
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .backgroundColor('#ECFBF5')
              .borderRadius(14)
          }
        }
        .padding(14)
        .width('100%')
        .backgroundColor('#F8FAFC')
        .borderRadius(18)
        .alignItems(HorizontalAlign.Start)
      }
    }
    .padding(20)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
  }

  @Builder
  dot(color: string) {
    Row()
      .width(6)
      .height(6)
      .borderRadius(3)
      .backgroundColor(color)
  }

  @Builder
  scannedMealButton(title: string, type: MealType, bgColor: string, tint: string) {
    Button(title)
      .layoutWeight(1)
      .height(34)
      .fontSize(12)
      .fontWeight(FontWeight.Bold)
      .fontColor(tint)
      .backgroundColor(bgColor)
      .borderRadius(14)
      .padding(0)
      .onClick(() => {
        this.assignScannedFoodToMeal(type);
      })
  }

  @Builder
  calorieMeta(title: string, value: string, unit: string, accent: string, bgColor: string) {
    Column({ space: 6 }) {
      Text(title)
        .fontSize(12)
        .fontColor('#94A3B8')

      Row({ space: 4 }) {
        Text(value)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(accent)

        if (unit.length > 0) {
          Text(unit)
            .fontSize(12)
            .fontColor('#94A3B8')
        }
      }
    }
    .padding(14)
    .layoutWeight(1)
    .backgroundColor(bgColor)
    .borderRadius(18)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  foodAction(item: MealActionItem) {
    Column({ space: 8 }) {
      Button() {
        if (mealActionIcon(item.id) !== undefined) {
          Image(mealActionIcon(item.id))
            .width(26)
            .height(26)
            .objectFit(ImageFit.Contain)
        } else {
          Text(item.glyph)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(item.tint)
        }
      }
        .width(42)
        .height(42)
        .backgroundColor(item.bgColor)
        .borderRadius(21)
        .onClick(() => {
          this.handleMealAction(item.type);
        })

      Text(item.label)
        .fontSize(12)
        .fontColor('#607184')
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  mealSummaryChip(title: string, value: number, bgColor: string, tint: string) {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(12)
        .fontColor('#607184')

      Text(`${value} \u5343\u5361`)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(tint)
    }
    .layoutWeight(1)
    .padding({ top: 10, bottom: 10 })
    .backgroundColor(bgColor)
    .borderRadius(16)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.openMealSheetByLabel(title);
    })
  }

  @Builder
  recordSection() {
    Column({ space: 16 }) {
      this.dailyCompletionCard()
      this.smartReminderCard()
      this.trendCalendarCard()
      this.goalAdjustmentCard()
      this.weightRecordCard()

      this.exerciseRecordCard()
    }
    .width('100%')
  }

  @Builder
  dailyCompletionCard() {
    Column({ space: 14 }) {
      Row() {
        Column({ space: 4 }) {
          Text('\u4eca\u65e5\u5b8c\u6210\u5ea6')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0F172A')

          Text(this.dailyCompletionSummary().headline)
            .fontSize(12)
            .lineHeight(18)
            .fontColor('#64748B')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Stack({ alignContent: Alignment.Center }) {
          Progress({ value: this.dailyCompletionSummary().percent, total: 100, type: ProgressType.Ring })
            .width(58)
            .height(58)
            .color('#36C79A')
            .backgroundColor('#E2E8F0')

          Text(`${this.dailyCompletionSummary().percent}%`)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0F172A')
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row({ space: 8 }) {
        ForEach(this.dailyCompletionSummary().items, (item: DailyCompletionItem) => {
          Column({ space: 6 }) {
            Text(item.title)
              .fontSize(12)
              .fontColor('#607184')

            Text(item.valueText)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(item.completed ? item.tint : '#94A3B8')

            Row()
              .width(8)
              .height(8)
              .borderRadius(4)
              .backgroundColor(item.completed ? item.tint : '#CBD5E1')
          }
          .layoutWeight(1)
          .padding({ top: 10, bottom: 10 })
          .backgroundColor(item.bgColor)
          .borderRadius(14)
          .alignItems(HorizontalAlign.Center)
        }, (item: DailyCompletionItem) => item.id)
      }
      .width('100%')

      Text(this.dailyCompletionSummary().actionText)
        .width('100%')
        .height(38)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#36C79A')
        .textAlign(TextAlign.Center)
        .backgroundColor('#ECFBF5')
        .borderRadius(14)
        .onClick(() => {
          this.handleDailyCompletionAction();
        })
    }
    .padding(18)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  smartReminderCard() {
    Column({ space: 12 }) {
      Row() {
        Text('\u667a\u80fd\u63d0\u9192')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')

        Text(this.smartReminders().length > 1 ? `${this.smartReminders().length} \u6761` : '\u4eca\u65e5')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#36C79A')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor('#ECFBF5')
          .borderRadius(12)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      ForEach(this.smartReminders(), (item: SmartReminder) => {
        Row({ space: 10 }) {
          Row()
            .width(8)
            .height(8)
            .borderRadius(4)
            .backgroundColor(item.tint)

          Column({ space: 4 }) {
            Text(item.title)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F172A')
            Text(item.message)
              .fontSize(12)
              .lineHeight(18)
              .fontColor('#64748B')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding(12)
        .backgroundColor(item.bgColor)
        .borderRadius(16)
        .alignItems(VerticalAlign.Top)
      }, (item: SmartReminder) => item.title)
    }
    .padding(18)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  trendCalendarCard() {
    Column({ space: 14 }) {
      Row() {
        Text('\u8d8b\u52bf\u65e5\u5386')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')

        Text(this.trendCalendarTitle())
          .fontSize(12)
          .fontColor('#607184')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Row({ space: 6 }) {
        ForEach(['\u4e00', '\u4e8c', '\u4e09', '\u56db', '\u4e94', '\u516d', '\u65e5'], (item: string) => {
          Text(item)
            .layoutWeight(1)
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#94A3B8')
            .textAlign(TextAlign.Center)
        })
      }
      .width('100%')

      Column({ space: 6 }) {
        ForEach(this.trendCalendarRows(), (row: TrendDaySummary[]) => {
          Row({ space: 6 }) {
            ForEach(row, (item: TrendDaySummary) => {
              this.trendDayChip(item)
            }, (item: TrendDaySummary) => item.dayKey)
          }
          .width('100%')
        }, (row: TrendDaySummary[]) => this.trendCalendarRowKey(row))
      }
      .width('100%')

      this.trendDayDetailCard(this.selectedTrendSummary())
    }
    .padding(18)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  trendDayChip(item: TrendDaySummary) {
    Column({ space: 6 }) {
      Text(item.label)
        .fontSize(10)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isTrendDaySelected(item.dayKey) ? '#FFFFFF' : '#607184')

      Row()
        .width(7)
        .height(7)
        .borderRadius(4)
        .backgroundColor(item.hasRecords ? (this.isTrendDaySelected(item.dayKey) ? '#FFFFFF' : '#36C79A') : '#CBD5E1')

      Text(item.weightText)
        .fontSize(10)
        .fontColor(this.isTrendDaySelected(item.dayKey) ? '#FFFFFF' : '#94A3B8')
        .maxLines(1)
    }
    .layoutWeight(1)
    .height(58)
    .padding({ top: 6, bottom: 6 })
    .backgroundColor(this.isTrendDaySelected(item.dayKey) ? '#36C79A' : '#F8FAFC')
    .borderRadius(16)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.selectTrendDay(item.dayKey);
    })
  }

  @Builder
  trendDayDetailCard(item: TrendDaySummary) {
    Column({ space: 10 }) {
      Text(`${item.label} \u8bb0\u5f55\u56de\u770b`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0F172A')

      Row({ space: 10 }) {
        this.trendMetric('\u6444\u5165', `${item.calories}`, 'kcal', '#FF9D4D', '#FFF7EE')
        this.trendMetric('\u996e\u6c34', `${item.water}`, 'ml', '#32C5F4', '#E9F9FF')
        this.trendMetric('\u8fd0\u52a8', `${item.exerciseCalories}`, 'kcal', '#36C79A', '#ECFBF5')
      }
      .width('100%')

      Text(this.trendDayDetailText(item.dayKey))
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#64748B')

      if (this.dayRecordDetails(item.dayKey).length > 0) {
        Column({ space: 8 }) {
          ForEach(this.dayRecordDetails(item.dayKey), (line: string) => {
            Text(line)
              .width('100%')
              .fontSize(12)
              .lineHeight(18)
              .fontColor('#334155')
              .padding({ left: 10, right: 10, top: 7, bottom: 7 })
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
          }, (line: string) => line)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#F8FAFC')
    .borderRadius(18)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  trendMetric(title: string, value: string, unit: string, tint: string, bgColor: string) {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(11)
        .fontColor('#64748B')
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(tint)
      Text(unit)
        .fontSize(10)
        .fontColor('#94A3B8')
    }
    .layoutWeight(1)
    .padding({ top: 10, bottom: 10 })
    .backgroundColor(bgColor)
    .borderRadius(14)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  goalAdjustmentCard() {
    Column({ space: 12 }) {
      Row() {
        Text('\u76ee\u6807\u52a8\u6001\u8c03\u6574')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')
        Text(this.goalAdjustment().paceText)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#36C79A')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor('#ECFBF5')
          .borderRadius(12)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      this.profileInsightCard('\u4eca\u65e5\u996e\u98df', this.goalAdjustment().calorieText, '#FFF7EE')
      this.profileInsightCard('\u5efa\u8bae\u8fd0\u52a8', this.goalAdjustment().exerciseText, '#ECFBF5')
    }
    .padding(18)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  weightRecordCard() {
    Column({ space: 18 }) {
      Row() {
        Column({ space: 4 }) {
          Text('\u4f53\u91cd\u8bb0\u5f55')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0F172A')

          Text(`${this.weightUpdateTime} \u66f4\u65b0`)
            .fontSize(12)
            .fontColor('#94A3B8')
        }
        .alignItems(HorizontalAlign.Start)

        Button() {
          this.plusGlyph('#36C79A', 18, 2.5)
        }
          .width(40)
          .height(40)
          .backgroundColor('#F2FCF9')
          .borderRadius(20)
          .padding(0)
          .onClick(() => {
            this.openWeightInput();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Row({ space: 6 }) {
        Text(this.weight.toFixed(2))
          .fontSize(34)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')

        Text('kg')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#94A3B8')
          .margin({ bottom: 4 })
      }
      .alignItems(VerticalAlign.Bottom)
    }
    .padding(20)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
  }

  @Builder
  waterRecordSheet() {
    Column({ space: 18 }) {
      Row() {
        Row({ space: 12 }) {
          Row() {
            Image($r('app.media.icon_status_water'))
              .width(28)
              .height(28)
              .objectFit(ImageFit.Contain)
          }
          .width(46)
          .height(46)
          .backgroundColor('#E9F9FF')
          .borderRadius(16)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)

          Column({ space: 4 }) {
            Text('\u8bbe\u7f6e\u5feb\u6377\u8bb0\u5f55')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F172A')

            Text(`\u4eca\u65e5\u5df2\u996e ${this.currentDayWaterTotal()} ml`)
              .fontSize(12)
              .fontColor('#64748B')
          }
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)

        Row({ space: 10 }) {
          Text(this.waterSheetTime)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#475569')
            .padding({ left: 14, right: 14, top: 8, bottom: 8 })
            .backgroundColor('#F8FAFC')
            .borderRadius(20)

          Button() {
            this.closeGlyph('#94A3B8', 16, 2)
          }
            .width(40)
            .height(40)
            .backgroundColor('#F8FAFC')
            .borderRadius(20)
            .padding(0)
            .onClick(() => {
              this.closeWaterSheet();
            })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 20, right: 20, top: 18 })

      Scroll() {
        Column({ space: 18 }) {
          Column({ space: 8 }) {
            Row({ space: 8 }) {
              Text(this.waterDraft.length > 0 ? this.waterDraft : '0')
                .fontSize(56)
                .fontWeight(FontWeight.Bold)
                .fontColor('#0F172A')

              Text('ml')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#32C5F4')
                .margin({ top: 24 })
            }
            .alignItems(VerticalAlign.Bottom)

            Row()
              .width(160)
              .height(3)
              .backgroundColor('#7DD3FC')
              .borderRadius(2)

            Text(`\u5df2\u9009\uff1a${this.selectedDrinkName()}`)
              .fontSize(14)
              .fontColor('#64748B')

            if (this.waterInputError.length > 0) {
              Text(this.waterInputError)
                .fontSize(13)
                .fontColor('#EF4444')
            } else {
              Text(`\u4eca\u65e5\u76ee\u6807 ${this.waterGoalMl()} ml\uff0c\u5f53\u524d\u8fdb\u5ea6 ${this.waterProgressPercent()}%`)
                .fontSize(13)
                .fontColor('#94A3B8')
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 8, bottom: 4 })

          Column({ space: 12 }) {
            Row() {
              Text('\u5feb\u6377\u996e\u54c1')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#0F172A')

              Text(this.selectedDrinkName())
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor('#32C5F4')
                .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                .backgroundColor('#E9F9FF')
                .borderRadius(12)
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)

            ForEach(this.waterPresetRows(), (row: DrinkPresetItem[]) => {
              Row({ space: 12 }) {
                ForEach(row, (item: DrinkPresetItem) => {
                  this.waterPresetCard(item)
                })
              }
              .width('100%')
            })
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 8 })
        }
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)

      Row({ space: 12 }) {
        Column({ space: 12 }) {
          Row({ space: 12 }) {
            this.waterKeyCell('1', false, () => { this.appendWaterDraft('1'); })
            this.waterKeyCell('2', false, () => { this.appendWaterDraft('2'); })
            this.waterKeyCell('3', false, () => { this.appendWaterDraft('3'); })
          }

          Row({ space: 12 }) {
            this.waterKeyCell('4', false, () => { this.appendWaterDraft('4'); })
            this.waterKeyCell('5', false, () => { this.appendWaterDraft('5'); })
            this.waterKeyCell('6', false, () => { this.appendWaterDraft('6'); })
          }

          Row({ space: 12 }) {
            this.waterKeyCell('7', false, () => { this.appendWaterDraft('7'); })
            this.waterKeyCell('8', false, () => { this.appendWaterDraft('8'); })
            this.waterKeyCell('9', false, () => { this.appendWaterDraft('9'); })
          }

          Row({ space: 12 }) {
            this.waterKeyCell('C', false, () => { this.clearWaterDraft(); })
            this.waterKeyCell('0', false, () => { this.appendWaterDraft('0'); })
            this.waterKeyCell('00', false, () => { this.appendWaterDraft('00'); })
          }
        }
        .layoutWeight(1)

        Column({ space: 12 }) {
          this.waterKeyButton('\u232b', false, () => {
            this.removeWaterDraftDigit();
          })

          Button('\u5b8c\u6210')
            .width(96)
            .height(156)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .backgroundColor('#32C5F4')
            .borderRadius(18)
            .onClick(() => {
              this.saveWaterIntake();
            })
        }
        .width(96)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 6, bottom: 24 })
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  exerciseRecordCard() {
    Column({ space: 18 }) {
      Row() {
        Text('\u8fd0\u52a8\u8bb0\u5f55')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')

        Button() {
          this.plusGlyph('#36C79A', 18, 2.5)
        }
          .width(40)
          .height(40)
          .backgroundColor('#F2FCF9')
          .borderRadius(20)
          .padding(0)
          .onClick(() => {
            this.openExerciseSheet();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Row({ space: 40 }) {
        Column({ space: 6 }) {
          Text('\u672c\u5468\u8fbe\u6210')
            .fontSize(12)
            .fontColor('#94A3B8')

          Row({ space: 4 }) {
            Text(`${this.exerciseGoalDaysThisWeek()}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F172A')

            Text('\u5929')
              .fontSize(12)
              .fontColor('#94A3B8')
              .margin({ top: 8 })
          }
        }
        .alignItems(HorizontalAlign.Start)

        Column({ space: 6 }) {
          Text('\u6bcf\u65e5\u5e73\u5747')
            .fontSize(12)
            .fontColor('#94A3B8')

          Row({ space: 4 }) {
            Text(`${this.exerciseDailyAverage()}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F172A')

            Text('kcal')
              .fontSize(12)
              .fontColor('#94A3B8')
              .margin({ top: 8 })
          }
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Column({ space: 8 }) {
        Row({ space: 12 }) {
          ForEach(this.exerciseBarHeights(), (height: number) => {
            Column() {
              Stack({ alignContent: Alignment.Bottom }) {
                Column()
                  .width(6)
                  .height(64)
                  .backgroundColor('#F1F5F9')
                  .borderRadius(3)

                Column()
                  .width(6)
                  .height(height)
                  .backgroundColor('#36C79A')
                  .borderRadius(3)
              }
              .height(64)
            }
            .layoutWeight(1)
            .height(64)
            .alignItems(HorizontalAlign.Center)
          })
        }
        .width('100%')
        .height(64)
        .alignItems(VerticalAlign.Bottom)

        Row({ space: 12 }) {
          ForEach(this.exerciseWeekLabels(), (label: string) => {
            Text(label)
              .layoutWeight(1)
              .fontSize(11)
              .fontColor('#94A3B8')
              .textAlign(TextAlign.Center)
          })
        }
        .width('100%')
      }

      if (this.exerciseRecords.length > 0) {
        Row({ space: 8 }) {
          Text('\u6700\u8fd1\u8bb0\u5f55')
            .fontSize(12)
            .fontColor('#94A3B8')

          Text(this.exerciseRecords[0].name)
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#36C79A')

          Text(`${this.exerciseRecords[0].calories} kcal`)
            .fontSize(12)
            .fontColor('#64748B')
        }
        .width('100%')
      }
    }
    .padding(20)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
  }

  @Builder
  exerciseRecordSheet() {
    Column() {
      Row() {
        Row({ space: 12 }) {
          Row() {
            Image($r('app.media.icon_meal_exercise'))
              .width(28)
              .height(28)
              .objectFit(ImageFit.Contain)
          }
          .width(46)
          .height(46)
          .backgroundColor('#ECFBF5')
          .borderRadius(16)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)

          Column({ space: 4 }) {
            Text('\u8fd0\u52a8\u8bb0\u5f55')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F172A')

            Text(`\u4eca\u65e5\u6d88\u8017 ${this.exerciseCaloriesBurned} kcal`)
              .fontSize(12)
              .fontColor('#64748B')
          }
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)

        Text(`\u4eca\u5929 ${this.exerciseSheetTime}`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#475569')
          .padding({ left: 14, right: 14, top: 8, bottom: 8 })
          .backgroundColor('#F8FAFC')
          .borderRadius(20)

        Button() {
          this.closeGlyph('#94A3B8', 16, 2)
        }
          .width(40)
          .height(40)
          .backgroundColor('#FFFFFF')
          .borderRadius(20)
          .padding(0)
          .onClick(() => {
            this.closeExerciseSheet();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 18 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Row() {
        Column({ space: 14 }) {
          Text('\u9009\u62e9\u4e00\u9879\u8fd0\u52a8\uff0c\u5b8c\u6210\u540e\u8bb0\u5165\u4eca\u65e5\u6d88\u8017')
            .fontSize(13)
            .fontColor('#94A3B8')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Button('\u4eca\u65e5\u8bb0\u5f55')
          .height(38)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#36C79A')
          .backgroundColor('#ECFBF5')
          .borderRadius(16)
          .onClick(() => {
            this.openExerciseHistory();
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 14 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Top)

      Row({ space: 0 }) {
        Column({ space: 8 }) {
          ForEach(this.exerciseCategories, (item: ExerciseCategoryItem) => {
            this.exerciseCategoryTab(item)
          }, (item: ExerciseCategoryItem) => item.id.toString())
        }
        .width(94)
        .padding({ top: 8, bottom: 8 })
        .backgroundColor('#F8FAFC')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 14 }) {
          Row({ space: 10 }) {
            TextInput({ text: this.exerciseSearchKeyword, placeholder: '\u641c\u7d22\u8fd0\u52a8\u540d\u79f0' })
              .layoutWeight(1)
              .height(44)
              .fontSize(14)
              .fontColor('#1F2937')
              .backgroundColor('#F8FAFC')
              .borderRadius(16)
              .padding({ left: 14, right: 14 })
              .onChange((value: string) => {
                this.exerciseSearchKeyword = value;
              })
          }
          .width('100%')

          Row() {
            Text(this.activeExerciseCategory)
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F172A')

            if (this.selectedExerciseId >= 0) {
              Text('\u5df2\u9009\u4e2d')
                .fontSize(12)
                .fontColor('#36C79A')
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .backgroundColor('#ECFBF5')
                .borderRadius(14)
            }
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)

          if (this.currentExerciseOptions().length === 0) {
            Column({ space: 8 }) {
              Text('\u6682\u65f6\u6ca1\u6709\u5339\u914d\u7684\u8fd0\u52a8')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#0F172A')

              Text('\u6362\u4e2a\u5173\u952e\u8bcd\u6216\u5207\u6362\u4e00\u4e2a\u7c7b\u522b\u8bd5\u8bd5')
                .fontSize(12)
                .fontColor('#94A3B8')
            }
            .width('100%')
            .padding({ top: 80, bottom: 18 })
            .alignItems(HorizontalAlign.Center)
          } else {
            Column({ space: 12 }) {
              ForEach(this.currentExerciseOptions(), (item: ExercisePresetItem) => {
                this.exerciseOptionRow(item)
              }, (item: ExercisePresetItem) => item.id.toString())
            }
            .width('100%')
            .padding({ bottom: 18 })
            .alignItems(HorizontalAlign.Start)
          }
        }
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8 })
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Column({ space: 10 }) {
        if (this.selectedExerciseSummary().length > 0) {
          Column({ space: 10 }) {
            Row({ space: 12 }) {
              Column({ space: 6 }) {
                Text('\u8bad\u7ec3\u65f6\u957f')
                  .fontSize(12)
                  .fontColor('#94A3B8')

                TextInput({ text: this.exerciseDurationDraft, placeholder: '30' })
                  .width(120)
                  .height(42)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#0F172A')
                  .backgroundColor('#F8FAFC')
                  .borderRadius(14)
                  .padding({ left: 14, right: 14 })
                  .type(InputType.Number)
                  .onChange((value: string) => {
                    this.exerciseDurationDraft = value;
                  })
              }
              .alignItems(HorizontalAlign.Start)

              Column({ space: 6 }) {
                Text('\u9884\u8ba1\u6d88\u8017')
                  .fontSize(12)
                  .fontColor('#94A3B8')

                Row({ space: 4 }) {
                  Text(`${this.selectedExerciseCaloriesValue()}`)
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#F97316')

                  Text('kcal')
                    .fontSize(12)
                    .fontColor('#94A3B8')
                    .margin({ top: 8 })
                }
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding({ left: 14, right: 14, top: 12, bottom: 12 })
            .backgroundColor('#F8FAFC')
            .borderRadius(16)
          }
          .width('100%')
        }

        Button(this.selectedExerciseId >= 0 ? '\u5b8c\u6210' : '\u5173\u95ed')
          .width('100%')
          .height(54)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#36C79A')
          .borderRadius(16)
          .onClick(() => {
            this.saveExerciseSelection();
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 28 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  exerciseCategoryTab(item: ExerciseCategoryItem) {
    Stack({ alignContent: Alignment.Start }) {
      if (this.activeExerciseCategory === item.label) {
        Column()
          .width(3)
          .height(46)
          .backgroundColor('#36C79A')
          .borderRadius(2)
      }

      Column({ space: 6 }) {
        if (exerciseCategoryIcon(item.label) !== undefined) {
          Image(exerciseCategoryIcon(item.label))
            .width(22)
            .height(22)
            .objectFit(ImageFit.Contain)
            .opacity(this.activeExerciseCategory === item.label ? 1 : 0.72)
        } else {
          Text(item.glyph)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.activeExerciseCategory === item.label ? item.tint : '#94A3B8')
        }

        Text(item.label)
          .fontSize(13)
          .fontWeight(this.activeExerciseCategory === item.label ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.activeExerciseCategory === item.label ? '#0F172A' : '#94A3B8')
      }
      .width('100%')
      .padding({ top: 14, bottom: 14 })
      .backgroundColor(this.activeExerciseCategory === item.label ? '#FFFFFF' : '#F8FAFC')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .onClick(() => {
      this.activeExerciseCategory = item.label;
      this.selectedExerciseId = -1;
    })
  }

  @Builder
  exerciseOptionRow(item: ExercisePresetItem) {
    Row({ space: 12 }) {
      Row() {
        if (exerciseCategoryIcon(item.category) !== undefined) {
          Image(exerciseCategoryIcon(item.category))
            .width(30)
            .height(30)
            .objectFit(ImageFit.Contain)
        } else {
          Text(item.glyph)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0F172A')
        }
      }
      .width(56)
      .height(56)
      .backgroundColor(item.bgColor)
      .borderRadius(18)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      Column({ space: 6 }) {
        Text(item.name)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')
          .maxLines(1)

        Row({ space: 4 }) {
          Text(`${item.calories}`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#F97316')

          Text(`\u5343\u5361 / ${item.duration}\u5206\u949f`)
            .fontSize(12)
            .fontColor('#94A3B8')
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.selectedExerciseId === item.id) {
        Row() {
          Text('\u5df2\u9009')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#36C79A')
        }
        .padding({ left: 10, right: 10, top: 8, bottom: 8 })
        .backgroundColor('#ECFBF5')
        .borderRadius(14)
      } else {
        Row() {
          this.plusGlyph('#36C79A', 14, 2)
        }
        .width(28)
        .height(28)
        .backgroundColor('#FFFFFF')
        .borderRadius(14)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
      }
    }
    .padding(14)
    .width('100%')
    .backgroundColor(this.selectedExerciseId === item.id ? '#F2FCF9' : '#FFFFFF')
    .borderRadius(20)
    .border({
      width: this.selectedExerciseId === item.id ? 1 : 0,
      color: this.selectedExerciseId === item.id ? '#B8F0DE' : '#FFFFFF'
    })
    .onClick(() => {
      if (this.selectedExerciseId === item.id) {
        this.selectedExerciseId = -1;
        this.exerciseDurationDraft = '';
      } else {
        this.selectedExerciseId = item.id;
        this.exerciseDurationDraft = item.duration.toString();
      }
    })
  }

  @Builder
  exerciseRecordRow(item: ExerciseRecordItem) {
    Row({ space: 12 }) {
      Column({ space: 4 }) {
        Text(item.name)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')

        Text(`${item.time}  \u00B7  ${item.duration}\u5206\u949f`)
          .fontSize(12)
          .fontColor('#94A3B8')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text(`${item.calories} kcal`)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#F97316')

      Button('\u5220\u9664')
        .height(32)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#F97316')
        .backgroundColor('#FFF3EA')
        .borderRadius(14)
        .onClick(() => {
          this.removeExerciseRecord(item.id);
        })
    }
    .padding(12)
    .width('100%')
    .backgroundColor('#F8FAFC')
    .borderRadius(16)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  exerciseHistorySheet() {
    Column() {
      Blank()
        .layoutWeight(1)
        .width('100%')
        .backgroundColor('#00000055')
        .onClick(() => {
          this.closeExerciseHistory();
        })

      Column({ space: 14 }) {
        Row() {
          Text('\u4eca\u65e5\u8bb0\u5f55')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0F172A')

          Button() {
            this.closeGlyph('#94A3B8', 14, 2)
          }
            .width(32)
            .height(32)
            .backgroundColor('#F8FAFC')
            .borderRadius(16)
            .padding(0)
            .onClick(() => {
              this.closeExerciseHistory();
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)

        Text(`${this.currentDayExerciseRecords().length} \u9879`)
          .fontSize(12)
          .fontColor('#94A3B8')

        if (this.currentDayExerciseRecords().length === 0) {
          Column({ space: 8 }) {
            Text('\u4eca\u5929\u8fd8\u6ca1\u6709\u8fd0\u52a8\u8bb0\u5f55')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F172A')

            Text('\u5148\u5728\u4e0a\u65b9\u9009\u4e00\u9879\u8fd0\u52a8\uff0c\u518d\u8f93\u5165\u8bad\u7ec3\u65f6\u957f')
              .fontSize(12)
              .fontColor('#94A3B8')
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding({ top: 28, bottom: 28 })
          .alignItems(HorizontalAlign.Center)
        } else if (this.currentDayExerciseRecords().length <= 3) {
          Column({ space: 10 }) {
            ForEach(this.currentDayExerciseRecords(), (item: ExerciseRecordItem) => {
              this.exerciseRecordRow(item)
            }, (item: ExerciseRecordItem) => item.id.toString())
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        } else {
          Scroll() {
            Column({ space: 10 }) {
              ForEach(this.currentDayExerciseRecords(), (item: ExerciseRecordItem) => {
                this.exerciseRecordRow(item)
              }, (item: ExerciseRecordItem) => item.id.toString())
            }
            .width('100%')
            .justifyContent(FlexAlign.Start)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .height(260)
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 28 })
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 24, topRight: 24 })
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  panelCard(title: string, value: string, subtitle: string, buttonText: string, action: () => void) {
    Column({ space: 14 }) {
      Row() {
        Column({ space: 6 }) {
          Text(title)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0F172A')

          Text(subtitle)
            .fontSize(12)
            .fontColor('#94A3B8')
        }

        Button() {
          this.plusGlyph('#36C79A', 18, 2.5)
        }
          .width(38)
          .height(38)
          .backgroundColor('#F2FCF9')
          .borderRadius(19)
          .padding(0)
          .onClick(() => {
            action();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Text(value)
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0F172A')

      Button(buttonText)
        .width('100%')
        .height(42)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#607184')
        .backgroundColor('#F8FAFC')
        .borderRadius(18)
        .onClick(() => {
          action();
        })
    }
    .padding(20)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
  }

  @Builder
  plusGlyph(color: string, size: number, thickness: number) {
    Stack({ alignContent: Alignment.Center }) {
      Row()
        .width(size)
        .height(thickness)
        .borderRadius(thickness / 2)
        .backgroundColor(color)

      Row()
        .width(thickness)
        .height(size)
        .borderRadius(thickness / 2)
        .backgroundColor(color)
    }
    .width(size)
    .height(size)
  }

  @Builder
  closeGlyph(color: string, size: number, thickness: number) {
    Stack({ alignContent: Alignment.Center }) {
      Row()
        .width(size)
        .height(thickness)
        .borderRadius(thickness / 2)
        .backgroundColor(color)
        .rotate({ angle: 45 })

      Row()
        .width(size)
        .height(thickness)
        .borderRadius(thickness / 2)
        .backgroundColor(color)
        .rotate({ angle: -45 })
    }
    .width(size)
    .height(size)
  }

  @Builder
  weightInputSheet() {
    Column() {
      Row() {
        Row()
          .width(40)
          .height(40)

        Text(`\u4eca\u5929 ${this.weightInputTime}`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#475569')
          .padding({ left: 14, right: 14, top: 8, bottom: 8 })
          .backgroundColor('#F8FAFC')
          .borderRadius(20)

        Button() {
          this.closeGlyph('#94A3B8', 16, 2)
        }
          .width(40)
          .height(40)
          .backgroundColor('#FFFFFF')
          .borderRadius(20)
          .padding(0)
          .onClick(() => {
            this.closeWeightInput();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 18 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Column({ space: 14 }) {
        Row({ space: 14 }) {
          if (this.showWeightRuler) {
            Text(this.weightDraft)
              .fontSize(62)
              .fontWeight(FontWeight.Bold)
              .fontColor('#36C79A')
          } else {
            TextInput({ text: this.weightDraft, placeholder: '0.00' })
              .width(230)
              .fontSize(62)
              .fontWeight(FontWeight.Bold)
              .fontColor('#36C79A')
              .textAlign(TextAlign.Center)
              .caretColor('#36C79A')
              .backgroundColor('#FFFFFF')
              .padding({ left: 0, right: 0, top: 0, bottom: 0 })
              .onChange((value: string) => {
                this.weightInputError = '';
                if (value.length === 0 || this.isWeightDraftValid(value)) {
                  this.weightDraft = value;
                }
              })
          }

          Column({ space: 4 }) {
            this.weightUnitButton('\u516c\u65a4', 'kg')
            this.weightUnitButton('\u65a4', 'jin')
          }
        }
        .alignItems(VerticalAlign.Center)

        Row()
          .width(180)
          .height(2)
          .backgroundColor('#B8F0DE')
          .borderRadius(1)

        if (this.showWeightRuler) {
          this.weightStepper()
        }

        Text(this.showWeightRuler ? '\u6ed1\u5c3a\u8f93\u5165' : '\u624b\u52a8\u8f93\u5165')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#36C79A')

        Text(this.weightInputError.length > 0
          ? this.weightInputError
          : (this.showWeightRuler
            ? '\u5de6\u53f3\u6ed1\u52a8\u7cbe\u51c6\u8c03\u8282\u4f53\u91cd'
            : '\u8bf7\u8f93\u5165\u4f60\u7684\u4f53\u91cd\u6570\u636e'))
          .fontSize(13)
          .fontColor(this.weightInputError.length > 0 ? '#EF4444' : '#94A3B8')
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 24, right: 24, top: 24, bottom: 24 })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column({ space: 12 }) {
        Button(this.showWeightRuler ? '\u952e\u76d8\u8f93\u5165' : '\u6ed1\u5c3a\u8f93\u5165')
          .width('100%')
          .height(52)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#475569')
          .backgroundColor('#F1F5F9')
          .borderRadius(16)
          .onClick(() => {
            this.showWeightRuler = !this.showWeightRuler;
            this.weightInputError = '';
          })

        Button('\u4fdd\u5b58')
          .width('100%')
          .height(54)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#36C79A')
          .borderRadius(16)
          .onClick(() => {
            this.saveWeightInput();
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 28 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  weightUnitButton(label: string, unit: 'kg' | 'jin') {
    Button() {
      Text(label)
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.weightDraftUnit === unit ? '#FFFFFF' : '#94A3B8')
        .maxLines(1)
    }
    .width(64)
    .height(28)
    .backgroundColor(this.weightDraftUnit === unit ? '#36C79A' : '#F1F5F9')
    .borderRadius(8)
    .padding({ left: 0, right: 0, top: 0, bottom: 0 })
    .onClick(() => {
      this.switchWeightUnit(unit);
    })
  }

  @Builder
  weightStepper() {
    Stack({ alignContent: Alignment.Top }) {
      Column({ space: 12 }) {
        Row({ space: 0 }) {
          ForEach(this.weightRulerTicks(), (item: number) => {
            Column({ space: 6 }) {
              Row()
                .width(2)
                .height(this.weightTickHeight(item))
                .borderRadius(1)
                .backgroundColor(this.weightTickColor(item))

              if (this.weightTickLabel(item).length > 0) {
                Text(this.weightTickLabel(item))
                  .fontSize(10)
                  .fontColor('#94A3B8')
              } else {
                Text(' ')
                  .fontSize(10)
                  .opacity(0)
              }
            }
            .width(12)
            .alignItems(HorizontalAlign.Center)
          }, (item: number) => item.toString())
        }
        .width(300)
        .justifyContent(FlexAlign.Center)
        .hitTestBehavior(HitTestMode.None)

        Slider({
          value: this.weightDraftDisplayValue(),
          min: this.weightDisplayMin(),
          max: this.weightDisplayMax(),
          step: this.weightDisplayStep(),
          style: SliderStyle.OutSet
        })
          .width(300)
          .blockSize({ width: 28, height: 28 })
          .blockColor('#01000000')
          .trackColor('#00000000')
          .selectedColor('#00000000')
          .trackThickness(28)
          .onChange((value: number, mode: SliderChangeMode) => {
            this.updateWeightDraftFromDisplay(value);
          })
      }
      .alignItems(HorizontalAlign.Center)
      .margin({ top: 12 })

      Column({ space: 4 }) {
        Row()
          .width(3)
          .height(42)
          .borderRadius(2)
          .backgroundColor('#36C79A')

        Row()
          .width(10)
          .height(10)
          .borderRadius(5)
          .backgroundColor('#36C79A')
      }
      .alignItems(HorizontalAlign.Center)
      .hitTestBehavior(HitTestMode.None)
    }
    .width('100%')
    .height(116)
  }

  @Builder
  smallRecordCard(title: string, value: string, subtitle: string, buttonText: string, action: () => void, bgColor: string, tint: string) {
    Column({ space: 12 }) {
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0F172A')

      Text(value)
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0F172A')

      Text(subtitle)
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#607184')

      Button(buttonText)
        .width('100%')
        .height(38)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(tint)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .onClick(() => {
          action();
        })
    }
    .padding(18)
    .layoutWeight(1)
    .backgroundColor(bgColor)
    .borderRadius(24)
    .alignItems(HorizontalAlign.Start)
  }

  waterCardSubtitle(): string {
    let latestRecord: WaterRecordItem | null = this.latestWaterRecord();
    let remaining: number = Math.max(0, this.waterGoalMl() - this.currentDayWaterTotal());
    if (latestRecord !== null) {
      if (remaining <= 0) {
        return `${latestRecord.drinkName} ${latestRecord.amount}ml\uff0c\u4eca\u65e5\u8865\u6c34\u5df2\u8fbe\u6807`;
      }
      return `${latestRecord.drinkName} ${latestRecord.amount}ml\uff0c\u8fd8\u5dee ${remaining}ml \u8fbe\u6210\u4eca\u65e5\u76ee\u6807`;
    }
    return `\u4eca\u65e5\u76ee\u6807 ${this.waterGoalMl()}ml\uff0c\u73b0\u5728\u53ef\u4ee5\u5148\u8bb0\u5f55\u7b2c\u4e00\u676f`;
  }

  waterCardButtonText(): string {
    if (this.currentDayWaterRecords().length > 0) {
      return '\u518d\u8bb0\u4e00\u676f';
    }
    return '\u53bb\u8bb0\u5f55';
  }

  recordRefreshKey(): string {
    return `${this.currentDayWaterTotal()}-${this.weight.toFixed(2)}-${this.calories}-${this.exerciseCaloriesBurned}-${this.steps}-${this.streakDays}-${this.weightUpdateTime}`;
  }

  dailyCompletionSummary(): DailyCompletionSummary {
    return buildDailyCompletionSummary(this.todayRecordedMealTypeCount(), this.water, this.waterGoalMl(),
      this.exerciseCaloriesBurned, this.hasWeightRecordToday());
  }

  aiSuggestions(): SuggestionItem[] {
    return buildAiSuggestions({
      water: this.water,
      waterGoal: this.waterGoalMl(),
      dinnerCalories: this.dinnerCalories,
      exerciseCalories: this.exerciseCaloriesBurned,
      daysSinceWeight: this.daysSinceLatestWeight(),
      weekLoss: this.weekLoss
    });
  }

  hasWeightRecordToday(): boolean {
    return latestWeightForDay(this.weightRecords, this.currentDayKey()) > 0;
  }

  handleDailyCompletionAction(): void {
    let summary: DailyCompletionSummary = this.dailyCompletionSummary();
    for (let index = 0; index < summary.items.length; index++) {
      let item: DailyCompletionItem = summary.items[index];
      if (item.completed) {
        continue;
      }
      if (item.id === 'meal') {
        this.openMealSheet(this.nextMealTypeToRecord());
        return;
      }
      if (item.id === 'water') {
        this.openWaterSheet();
        return;
      }
      if (item.id === 'exercise') {
        this.openExerciseSheet();
        return;
      }
      this.openWeightInput();
      return;
    }
    this.openWeeklyReportInAi();
  }

  nextMealTypeToRecord(): MealType {
    if (this.breakfastCalories <= 0) {
      return 'breakfast';
    }
    if (this.lunchCalories <= 0) {
      return 'lunch';
    }
    if (this.dinnerCalories <= 0) {
      return 'dinner';
    }
    return 'snack';
  }

  trendWindowDayKeys(): string[] {
    return buildMonthCalendarDayKeys(this.trendSelectedDayKey());
  }

  trendDaySummaries(): TrendDaySummary[] {
    return buildTrendDaySummaries(this.trendWindowDayKeys(), this.mealRecords, this.waterRecords,
      this.exerciseRecords, this.weightRecords);
  }

  trendSelectedDayKey(): string {
    return this.selectedTrendDayKey.length > 0 ? this.selectedTrendDayKey : this.currentDayKey();
  }

  isTrendDaySelected(dayKey: string): boolean {
    return dayKey === this.trendSelectedDayKey();
  }

  selectTrendDay(dayKey: string): void {
    this.selectedTrendDayKey = dayKey;
  }

  selectedTrendSummary(): TrendDaySummary {
    let summaries: TrendDaySummary[] = this.trendDaySummaries();
    let selectedDayKey: string = this.trendSelectedDayKey();
    for (let index = 0; index < summaries.length; index++) {
      if (summaries[index].dayKey === selectedDayKey) {
        return summaries[index];
      }
    }
    return summaries[summaries.length - 1];
  }

  trendCalendarRows(): TrendDaySummary[][] {
    let summaries: TrendDaySummary[] = this.trendDaySummaries();
    let rows: TrendDaySummary[][] = [];
    for (let index = 0; index < summaries.length; index += 7) {
      rows.push(summaries.slice(index, index + 7));
    }
    return rows;
  }

  trendCalendarRowKey(row: TrendDaySummary[]): string {
    let keys: string[] = [];
    row.forEach((item: TrendDaySummary) => {
      keys.push(item.dayKey);
    });
    return keys.join('-');
  }

  trendCalendarTitle(): string {
    return monthTitleFromKey(this.trendSelectedDayKey());
  }

  trendDayDetailText(dayKey: string): string {
    let mealCount: number = this.mealCountForDay(dayKey);
    let waterCount: number = this.waterCountForDay(dayKey);
    let weightText: string = this.weightTextForDay(dayKey);
    return buildTrendDayDetailText(mealCount, waterCount, weightText);
  }

  mealCountForDay(dayKey: string): number {
    return countMealsForDay(this.mealRecords, dayKey);
  }

  waterCountForDay(dayKey: string): number {
    return countWaterRecordsForDay(this.waterRecords, dayKey);
  }

  weightTextForDay(dayKey: string): string {
    return buildWeightTextForDay(this.weightRecords, dayKey);
  }

  dayRecordDetails(dayKey: string): string[] {
    return buildDayRecordDetails(dayKey, this.mealRecords, this.waterRecords, this.exerciseRecords, this.weightRecords);
  }

  smartReminders(): SmartReminder[] {
    let currentHour: number = new Date().getHours();
    return buildSmartReminders(this.currentDayWaterTotal(), this.waterGoalMl(), this.dinnerCalories,
      this.daysSinceLatestWeight(), currentHour >= 18);
  }

  daysSinceLatestWeight(): number {
    if (this.weightRecords.length === 0) {
      return 7;
    }
    for (let offset = 0; offset >= -14; offset--) {
      let dayKey: string = this.dayKeyFromOffset(offset);
      for (let index = 0; index < this.weightRecords.length; index++) {
        if (this.weightRecords[index].dayKey === dayKey) {
          return Math.abs(offset);
        }
      }
    }
    return 15;
  }

  goalAdjustment(): GoalAdjustment {
    return buildGoalAdjustment(this.calories, this.exerciseCaloriesBurned, this.weekLoss,
      Number(this.weeklyGoalValueText()));
  }

  todayRecordedMealTypeCount(): number {
    let count: number = 0;
    if (this.breakfastCalories > 0) {
      count += 1;
    }
    if (this.lunchCalories > 0) {
      count += 1;
    }
    if (this.dinnerCalories > 0) {
      count += 1;
    }
    return count;
  }

  achievementSummary(): AchievementSummary {
    return buildAchievementSummary(this.streakDays, this.water, this.waterGoalMl(), this.exerciseCaloriesBurned,
      this.todayRecordedMealTypeCount());
  }

  achievementLinesText(): string {
    let summary: AchievementSummary = this.achievementSummary();
    if (summary.lines.length === 0) {
      return '\u4eca\u5929\u5148\u5b8c\u6210\u4e00\u9879\u8bb0\u5f55\uff0c\u79ef\u5206\u4f1a\u5728\u8fd9\u91cc\u7d2f\u52a0\u3002';
    }
    return summary.lines.join('\uff0c');
  }

  exportHealthData(): void {
    this.dataExportPreview = buildHealthDataCsv(this.mealRecords, this.waterRecords, this.weightRecords,
      this.exerciseRecords);
    this.profileActionMessage = `CSV \u5907\u4efd\u5df2\u751f\u6210\uff0c\u5171 ${this.exportDataLineCount()} \u884c\u8bb0\u5f55`;
  }

  exportDataLineCount(): number {
    if (this.dataExportPreview.length === 0) {
      return 0;
    }
    return this.dataExportPreview.split('\n').length - 1;
  }

  dataExportSummary(): string {
    if (this.dataExportPreview.length === 0) {
      return '\u70b9\u51fb\u5e95\u90e8\u201c\u751f\u6210 CSV \u5907\u4efd\u201d\uff0c\u4f1a\u628a\u996e\u98df\u3001\u996e\u6c34\u3001\u4f53\u91cd\u548c\u8fd0\u52a8\u6574\u7406\u6210 CSV \u6587\u672c\u3002';
    }
    let lines: string[] = this.dataExportPreview.split('\n');
    let previewLines: string[] = [];
    let maxLines: number = Math.min(4, lines.length);
    for (let index = 0; index < maxLines; index++) {
      previewLines.push(lines[index]);
    }
    return previewLines.join('\n');
  }

  awardPoints(points: number): void {
    if (points <= 0) {
      return;
    }
    this.profilePoints += points;
  }

  waterGoalMl(): number {
    return getWaterGoalMl(this.weight);
  }

  waterProgressPercent(): number {
    return getWaterProgressPercent(this.currentDayWaterTotal(), this.waterGoalMl());
  }

  currentHealthDayKey(): string {
    if (this.activeHealthDayKey.length > 0) {
      return this.activeHealthDayKey;
    }
    return this.currentDayKey();
  }

  currentDayWaterRecords(): WaterRecordItem[] {
    return waterRecordsForDay(this.waterRecords, this.currentHealthDayKey());
  }

  currentDayWaterTotal(): number {
    return this.water;
  }

  syncWaterIntake(): void {
    this.refreshWaterCardState();
  }

  latestWaterRecordForDisplay(): WaterRecordItem | null {
    return getLatestWaterRecordForDisplay(this.waterRecords, this.currentHealthDayKey(), this.water);
  }

  refreshWaterCardState(): void {
    let total: number = Math.max(0, this.water);
    let cardState = buildWaterCardDisplayStateFromTotal(total, this.waterGoalMl(), this.latestWaterRecordForDisplay());
    this.water = cardState.total;
    this.waterCardValueText = cardState.valueText;
    this.waterCardSubtitleText = cardState.subtitleText;
    this.waterCardActionText = cardState.buttonText;
  }

  latestWaterRecord(): WaterRecordItem | null {
    return getLatestWaterRecord(this.waterRecords, this.currentHealthDayKey());
  }

  openWaterSheet(): void {
    this.ensureDailyHealthStateCurrent();
    this.waterSheetTime = this.currentClock();
    this.waterDraft = '350';
    this.selectedDrinkId = this.selectedDrinkId > 0 ? this.selectedDrinkId : 1;
    this.waterInputError = '';
    this.isWaterSheetOpen = true;
  }

  closeWaterSheet(): void {
    this.isWaterSheetOpen = false;
    this.waterInputError = '';
  }

  waterPresetRows(): DrinkPresetItem[][] {
    return buildWaterPresetRows(this.waterPresets);
  }


  @Builder
  waterPresetCard(item: DrinkPresetItem) {
    Row({ space: 10 }) {
      Row() {
        if (waterPresetIcon(item.id) !== undefined) {
          Image(waterPresetIcon(item.id))
            .width(28)
            .height(28)
            .objectFit(ImageFit.Contain)
        } else {
          Text(item.glyph)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(item.tint)
        }
      }
      .width(40)
      .height(40)
      .backgroundColor(this.isWaterPresetSelected(item.id) ? '#FFFFFF' : item.bgColor)
      .borderRadius(14)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      Text(item.label)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#0F172A')
        .maxLines(1)
        .layoutWeight(1)
    }
    .layoutWeight(1)
    .height(72)
    .padding({ left: 14, right: 14 })
    .backgroundColor(this.isWaterPresetSelected(item.id) ? '#DFF6FF' : '#F8FAFC')
    .border({
      width: this.isWaterPresetSelected(item.id) ? 2 : 1,
      color: this.isWaterPresetSelected(item.id) ? '#32C5F4' : '#EDF2F7'
    })
    .borderRadius(18)
    .onClick(() => {
      this.selectedDrinkId = item.id;
    })
  }

  isWaterPresetSelected(id: number): boolean {
    return this.selectedDrinkId === id;
  }

  @Builder
  waterKeyCell(label: string, primary: boolean, action: () => void) {
    Column() {
      this.waterKeyButton(label, primary, action)
    }
    .layoutWeight(1)
  }

  @Builder
  waterKeyButton(label: string, primary: boolean, action: () => void) {
    Button(label)
      .width('100%')
      .height(72)
      .fontSize(primary ? 20 : 18)
      .fontWeight(FontWeight.Bold)
      .fontColor(primary ? '#FFFFFF' : '#0F172A')
      .backgroundColor(primary ? '#32C5F4' : '#F8FAFC')
      .borderRadius(18)
      .padding(0)
      .onClick(() => {
        action();
      })
  }

  appendWaterDraft(value: string): void {
    let nextDraft: string = this.waterDraft;
    if (nextDraft === '0') {
      nextDraft = '';
    }
    nextDraft += value;
    if (nextDraft.length > 4) {
      return;
    }

    let numericValue: number = Number(nextDraft);
    if (Number.isNaN(numericValue) || numericValue > 3000) {
      return;
    }
    this.waterDraft = nextDraft;
    this.waterInputError = '';
  }

  removeWaterDraftDigit(): void {
    if (this.waterDraft.length === 0) {
      return;
    }
    this.waterDraft = this.waterDraft.substring(0, this.waterDraft.length - 1);
    this.waterInputError = '';
  }

  clearWaterDraft(): void {
    this.waterDraft = '';
    this.waterInputError = '';
  }

  selectedDrinkName(): string {
    return getSelectedDrinkName(this.waterPresets, this.selectedDrinkId);
  }

  saveWaterIntake(): void {
    let amount: number = Number(this.waterDraft);
    if (Number.isNaN(amount) || amount <= 0) {
      this.waterInputError = '\u8bf7\u8f93\u5165\u6709\u6548\u7684\u6beb\u5347\u6570';
      return;
    }

    this.ensureDailyHealthStateCurrent();
    let previousWater: number = this.water;
    let nextRecord: WaterRecordItem = {
      id: Date.now(),
      amount: amount,
      drinkName: this.selectedDrinkName(),
      time: this.waterSheetTime,
      dayKey: this.currentHealthDayKey()
    };
    this.waterRecords = [nextRecord, ...this.waterRecords];
    this.water = Math.max(0, this.water + amount);
    if (previousWater < this.waterGoalMl() && this.water >= this.waterGoalMl()) {
      this.awardPoints(10);
    }
    this.syncWaterIntake();
    this.refreshRecordModuleKeepingScroll();
    this.isWaterSheetOpen = false;
    this.waterInputError = '';
    this.queuePersistAppState();
  }

  @Builder
  mealRecordSheet() {
    Column() {
      Row() {
        Row({ space: 12 }) {
          Row() {
            Image(mealTypeIcon(this.activeMealType))
              .width(28)
              .height(28)
              .objectFit(ImageFit.Contain)
          }
          .width(46)
          .height(46)
          .backgroundColor(mealBgColor(this.activeMealType))
          .borderRadius(16)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)

          Column({ space: 4 }) {
            Text(mealDisplayName(this.activeMealType))
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F172A')

            Text(`\u672c\u9910 ${this.currentMealCaloriesValue()} \u5343\u5361`)
              .fontSize(12)
              .fontColor('#64748B')
          }
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)

        Text(`\u4eca\u5929 ${this.mealSheetTime}`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#475569')
          .padding({ left: 14, right: 14, top: 8, bottom: 8 })
          .backgroundColor('#F8FAFC')
          .borderRadius(20)

        Button() {
          this.closeGlyph('#94A3B8', 16, 2)
        }
          .width(40)
          .height(40)
          .backgroundColor('#FFFFFF')
          .borderRadius(20)
          .padding(0)
          .onClick(() => {
            this.closeMealSheet();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 18 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column({ space: 18 }) {
          Column({ space: 12 }) {
            Row({ space: 8 }) {
              Image($r('app.media.icon_camera_scan'))
                .width(22)
                .height(22)
                .objectFit(ImageFit.Contain)

              Text('\u641c\u7d22\u98df\u7269\u5e93')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#0F172A')
            }
            .alignItems(VerticalAlign.Center)

            Row({ space: 10 }) {
              TextInput({ text: this.mealSearchKeyword, placeholder: '\u4f8b\u5982\uff1a\u82f9\u679c\u3001\u9e21\u80f8\u8089\u3001\u756a\u8304\u7092\u86cb' })
                .layoutWeight(1)
                .height(44)
                .fontSize(14)
                .fontColor('#1F2937')
                .backgroundColor('#F8FAFC')
                .borderRadius(16)
                .padding({ left: 14, right: 14 })
                .onChange((value: string) => {
                  this.mealSearchKeyword = value;
                })

              Button(this.isMealSearching ? '\u641c\u7d22\u4e2d' : '\u641c\u7d22')
                .height(44)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .backgroundColor(this.isMealSearching ? '#B7C2D1' : '#36C79A')
                .borderRadius(16)
                .onClick(() => {
                  this.searchMealFoods();
                })
            }
            .width('100%')

            if (this.mealSearchError.length > 0) {
              Text(this.mealSearchError)
                .fontSize(12)
                .lineHeight(18)
                .fontColor('#F97316')
            }

            if (this.mealSearchResults.length > 0) {
              Column({ space: 10 }) {
                ForEach(this.mealSearchResults, (item: BooheeFoodItem) => {
                  this.mealSearchResultRow(item)
                }, (item: BooheeFoodItem) => item.code.length > 0 ? item.code : item.name)
              }
              .width('100%')
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          this.manualFoodCard()

          Row({ space: 12 }) {
            Column({ space: 8 }) {
              Text('\u672c\u9910\u5df2\u6444\u5165')
                .fontSize(12)
                .fontColor('#607184')

              Row({ space: 4 }) {
                Text(`${this.currentMealCaloriesValue()}`)
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(mealTint(this.activeMealType))

                Text('\u5343\u5361')
                  .fontSize(12)
                  .fontColor('#94A3B8')
              }
            }
            .layoutWeight(1)
            .padding(16)
            .backgroundColor(mealBgColor(this.activeMealType))
            .borderRadius(18)
            .alignItems(HorizontalAlign.Start)

            Column({ space: 8 }) {
              Text('\u4eca\u65e5\u603b\u6444\u5165')
                .fontSize(12)
                .fontColor('#607184')

              Row({ space: 4 }) {
                Text(`${this.calories}`)
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#36C79A')

                Text('\u5343\u5361')
                  .fontSize(12)
                  .fontColor('#94A3B8')
              }
            }
            .layoutWeight(1)
            .padding(16)
            .backgroundColor('#ECFBF5')
            .borderRadius(18)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')

          if (this.foodFavorites.length > 0) {
            Column({ space: 12 }) {
              Row() {
                Text('\u98df\u7269\u6536\u85cf')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#0F172A')

                Text('\u4e00\u952e\u6dfb\u52a0')
                  .fontSize(12)
                  .fontColor('#36C79A')
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)

              if (this.favoriteEditMessage.length > 0) {
                Text(this.favoriteEditMessage)
                  .fontSize(12)
                  .fontColor('#F97316')
              }

              if (this.editingFavoriteId > 0) {
                this.favoriteEditCard()
              }

              ForEach(this.favoriteFoodRows(), (row: FavoriteFoodItem[]) => {
                Row({ space: 12 }) {
                  ForEach(row, (item: FavoriteFoodItem) => {
                    this.favoriteFoodCard(item)
                  }, (item: FavoriteFoodItem) => item.id.toString())
                }
                .width('100%')
              }, (row: FavoriteFoodItem[]) => this.favoriteFoodRowKey(row))
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }

          Column({ space: 12 }) {
            Text('\u5e38\u7528\u98df\u7269')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#0F172A')

            ForEach(this.currentMealPresetRows(), (row: MealPresetItem[]) => {
              Row({ space: 12 }) {
                ForEach(row, (item: MealPresetItem) => {
                  this.mealPresetCard(item)
                }, (item: MealPresetItem) => item.id.toString())
              }
              .width('100%')
            }, (row: MealPresetItem[]) => this.mealPresetRowKey(row))
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          Column({ space: 12 }) {
            Row() {
              Text('\u672c\u9910\u8bb0\u5f55')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#0F172A')

              Text(`${this.currentMealRecords().length} \u9879`)
                .fontSize(12)
                .fontColor('#94A3B8')
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)

            if (this.currentMealRecords().length === 0) {
              this.emptyMealState()
            } else {
              Column({ space: 10 }) {
                ForEach(this.currentMealRecords(), (item: MealRecordItem) => {
                  this.mealRecordRow(item)
                }, (item: MealRecordItem) => item.id.toString())
              }
              .width('100%')
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .padding({ left: 20, right: 20, top: 12, bottom: 32 })
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')

      Column() {
        Button('\u5b8c\u6210')
          .width('100%')
          .height(54)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#36C79A')
          .borderRadius(16)
          .onClick(() => {
            this.closeMealSheet();
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 28 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  mealOverviewCard(title: string, value: string, unit: string, tint: string, bgColor: string) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(12)
        .fontColor('#607184')

      Row({ space: 4 }) {
        Text(value)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(tint)

        Text(unit)
          .fontSize(12)
          .fontColor('#94A3B8')
      }
    }
    .layoutWeight(1)
    .padding(16)
    .backgroundColor(bgColor)
    .borderRadius(18)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  manualFoodCard() {
    Column({ space: 10 }) {
      Row() {
        Text('\u624b\u52a8\u6dfb\u52a0')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')

        Text('\u98df\u7269 + \u70ed\u91cf')
          .fontSize(12)
          .fontColor('#94A3B8')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Row({ space: 10 }) {
        TextInput({ text: this.manualFoodNameDraft, placeholder: '\u98df\u7269\u540d' })
          .layoutWeight(1)
          .height(42)
          .fontSize(14)
          .fontColor('#1F2937')
          .backgroundColor('#F8FAFC')
          .borderRadius(14)
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => {
            this.manualFoodNameDraft = value;
            this.manualFoodError = '';
          })

        TextInput({ text: this.manualFoodCaloriesDraft, placeholder: 'kcal' })
          .width(86)
          .height(42)
          .fontSize(14)
          .fontColor('#1F2937')
          .backgroundColor('#F8FAFC')
          .borderRadius(14)
          .padding({ left: 12, right: 12 })
          .type(InputType.Number)
          .onChange((value: string) => {
            this.manualFoodCaloriesDraft = value;
            this.manualFoodError = '';
          })
      }
      .width('100%')

      if (this.manualFoodError.length > 0) {
        Text(this.manualFoodError)
          .fontSize(12)
          .fontColor('#F97316')
      }

      Row({ space: 10 }) {
        Button('\u52a0\u5165\u672c\u9910')
          .layoutWeight(1)
          .height(40)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#36C79A')
          .borderRadius(14)
          .onClick(() => {
            this.addManualFoodRecord(false);
          })

        Button('\u52a0\u5165\u5e76\u6536\u85cf')
          .layoutWeight(1)
          .height(40)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#36C79A')
          .backgroundColor('#ECFBF5')
          .borderRadius(14)
          .onClick(() => {
            this.addManualFoodRecord(true);
          })
      }
      .width('100%')
    }
    .padding(14)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  mealPresetCard(item: MealPresetItem) {
    Button() {
      Column({ space: 8 }) {
        Row() {
          Text(item.name)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0F172A')
            .layoutWeight(1)

          Row() {
            this.plusGlyph(mealTint(item.mealType), 14, 2)
          }
            .width(28)
            .height(28)
            .backgroundColor('#FFFFFF')
            .borderRadius(14)
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Text(item.subtitle)
          .fontSize(12)
          .fontColor('#94A3B8')

        Text(`${item.calories} \u5343\u5361`)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(mealTint(item.mealType))
      }
      .padding(14)
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .layoutWeight(1)
    .backgroundColor(mealBgColor(item.mealType))
    .borderRadius(18)
    .padding(0)
    .onClick(() => {
      this.addMealRecord(item);
    })
  }

  @Builder
  favoriteFoodCard(item: FavoriteFoodItem) {
    Column({ space: 8 }) {
      Row() {
        Text(item.name)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')
          .layoutWeight(1)
          .maxLines(1)

        Text('\u6536')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('#36C79A')
          .padding({ left: 7, right: 7, top: 4, bottom: 4 })
          .backgroundColor('#FFFFFF')
          .borderRadius(10)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(`${item.calories} \u5343\u5361`)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(mealTint(this.activeMealType))

      Text(item.source)
        .fontSize(11)
        .fontColor('#94A3B8')

      Row({ space: 6 }) {
        Button('\u6dfb\u52a0')
          .layoutWeight(1)
          .height(30)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#36C79A')
          .borderRadius(12)
          .onClick(() => {
            this.addFavoriteFoodRecord(item);
          })

        Button('\u7f16\u8f91')
          .layoutWeight(1)
          .height(30)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4B8DFF')
          .backgroundColor('#EEF4FF')
          .borderRadius(12)
          .onClick(() => {
            this.openFavoriteEditor(item);
          })

        Button('\u5220\u9664')
          .layoutWeight(1)
          .height(30)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('#F97316')
          .backgroundColor('#FFF3EA')
          .borderRadius(12)
          .onClick(() => {
            this.removeFavoriteFood(item.id);
          })
      }
      .width('100%')
    }
    .padding(14)
    .layoutWeight(1)
    .backgroundColor('#ECFBF5')
    .borderRadius(18)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  favoriteEditCard() {
    Column({ space: 10 }) {
      Text('\u7f16\u8f91\u6536\u85cf')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0F172A')

      Row({ space: 10 }) {
        TextInput({ text: this.favoriteEditNameDraft, placeholder: '\u98df\u7269\u540d' })
          .layoutWeight(1)
          .height(40)
          .fontSize(13)
          .fontColor('#1F2937')
          .backgroundColor('#FFFFFF')
          .borderRadius(14)
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => {
            this.favoriteEditNameDraft = value;
            this.favoriteEditMessage = '';
          })

        TextInput({ text: this.favoriteEditCaloriesDraft, placeholder: 'kcal' })
          .width(84)
          .height(40)
          .fontSize(13)
          .fontColor('#1F2937')
          .backgroundColor('#FFFFFF')
          .borderRadius(14)
          .padding({ left: 12, right: 12 })
          .type(InputType.Number)
          .onChange((value: string) => {
            this.favoriteEditCaloriesDraft = value;
            this.favoriteEditMessage = '';
          })
      }
      .width('100%')

      Row({ space: 10 }) {
        Button('\u4fdd\u5b58')
          .layoutWeight(1)
          .height(36)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#36C79A')
          .borderRadius(12)
          .onClick(() => {
            this.saveFavoriteEdit();
          })

        Button('\u53d6\u6d88')
          .layoutWeight(1)
          .height(36)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#607184')
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .onClick(() => {
            this.closeFavoriteEditor();
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#F8FAFC')
    .borderRadius(18)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  mealSearchResultRow(item: BooheeFoodItem) {
    Row({ space: 12 }) {
      Column({ space: 4 }) {
        Row({ space: 6 }) {
          Text(item.name)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0F172A')
            .maxLines(1)

          Text(healthLightLabel(item.healthLight))
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .padding({ left: 6, right: 6, top: 3, bottom: 3 })
            .backgroundColor(healthLightColor(item.healthLight))
            .borderRadius(10)
        }

        Text(`${item.calories} \u5343\u5361 / ${item.weight}g${item.isLiquid ? '  \u00b7  \u6db2\u4f53' : ''}`)
          .fontSize(12)
          .fontColor('#607184')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column({ space: 6 }) {
        Row() {
          this.plusGlyph(mealTint(this.activeMealType), 14, 2)
        }
          .width(30)
          .height(30)
          .backgroundColor('#FFFFFF')
          .borderRadius(15)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.addSearchFoodRecord(item);
          })

        Button('\u6536\u85cf')
          .height(28)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('#36C79A')
          .backgroundColor('#ECFBF5')
          .borderRadius(12)
          .padding({ left: 8, right: 8 })
          .onClick(() => {
            this.addFavoriteFood(item.name, item.calories, '\u98df\u7269\u5e93');
          })
      }
    }
    .padding(14)
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#F8FAFC')
    .borderRadius(18)
  }

  @Builder
  mealRecordRow(item: MealRecordItem) {
    Row({ space: 12 }) {
      Column({ space: 4 }) {
        Text(item.name)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')

        Text(`${item.time} \u8bb0\u5f55`)
          .fontSize(12)
          .fontColor('#94A3B8')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text(`${item.calories} \u5343\u5361`)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(mealTint(item.mealType))

      Button('\u5220\u9664')
        .height(34)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#F97316')
        .backgroundColor('#FFF3EA')
        .borderRadius(14)
        .onClick(() => {
          this.removeMealRecord(item.id);
        })
    }
    .padding(14)
    .width('100%')
    .backgroundColor('#F8FAFC')
    .borderRadius(18)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  emptyMealState() {
    Column({ space: 8 }) {
      Text('\u8fd8\u6ca1\u6709\u8bb0\u5f55')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0F172A')

      Text('\u5148\u4ece\u4e0a\u65b9\u5e38\u7528\u98df\u7269\u91cc\u70b9\u4e00\u4e2a\uff0c\u6216\u8005\u56de\u5230\u4e0a\u4e00\u9875\u62cd\u7167\u8bc6\u522b')
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#94A3B8')
        .textAlign(TextAlign.Center)
    }
    .padding({ left: 20, right: 20, top: 26, bottom: 26 })
    .width('100%')
    .backgroundColor('#F8FAFC')
    .borderRadius(18)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  progressLine(value: number, tint: string) {
    Stack({ alignContent: Alignment.Start }) {
      Row()
        .width('100%')
        .height(10)
        .backgroundColor('#E9EFF5')
        .borderRadius(8)

      Row()
        .width(this.progressWidth(value))
        .height(10)
        .backgroundColor(tint)
        .borderRadius(8)
    }
    .width('100%')
  }

  @Builder
  foodScanOverlay() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')

      Column({ space: 22 }) {
        Stack({ alignContent: Alignment.Center }) {
          Column()
            .width(260)
            .height(260)
            .borderRadius(24)
            .borderWidth(2)
            .borderColor('#36C79A')
            .backgroundColor('#1536C79A')

          Column()
            .width(236)
            .height(2)
            .backgroundColor('#36C79A')
        }

        Row({ space: 10 }) {
          LoadingProgress()
            .width(22)
            .height(22)
            .color('#36C79A')

          Text(this.foodScanStatus)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#36C79A')
        }
        .padding({ left: 18, right: 18, top: 14, bottom: 14 })
        .backgroundColor('#FFFFFF')
        .borderRadius(24)
      }
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  weightArcGauge() {
    Stack({ alignContent: Alignment.Center }) {
      Canvas(this.weightArcContext)
        .width(230)
        .height(132)
        .onReady(() => {
          this.drawWeightArc();
        })

      Column({ space: 6 }) {
        Text(this.weightPlanValueText())
          .fontSize(42)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')

        Text(this.weightPlanValueLabel())
          .fontSize(13)
          .fontColor('#94A3B8')
      }
      .margin({ top: 6 })
    }
    .width(230)
    .height(132)
  }

  weightProgress(): number {
    let weeklyTarget: number = this.weightPlanWeeklyTarget();
    if (weeklyTarget <= 0) {
      return 0;
    }
    return clampUnitProgress(this.weekLoss / weeklyTarget);
  }

  clamp(value: number): number {
    return clampUnitProgress(value);
  }

  progressWidth(value: number): string {
    return formatProgressWidth(value);
  }

  weightPlanWeeklyTarget(): number {
    return parseWeightPlanWeeklyTarget(this.profileWeeklyTargetDraft, this.onboardingWeeklyTarget);
  }

  weightPlanTargetWeight(): number {
    return getWeightPlanTargetWeight(this.onboardingTargetWeight, this.weight);
  }

  weightPlanStartWeight(): number {
    return getWeightPlanStartWeight(this.weightRecords, this.weight);
  }

  weightPlanWeekNumber(): number {
    return getWeightPlanWeekNumber(this.weightRecords, this.currentDayKey());
  }

  weightPlanValueText(): string {
    return getWeightPlanValueText(this.weekLoss);
  }

  weightPlanValueLabel(): string {
    return getWeightPlanValueLabel(this.weekLoss);
  }

  drawWeightArc(): void {
    let context = this.weightArcContext;
    let progress = this.weightProgress();
    let width = 230;
    let height = 132;
    let centerX = 115;
    let centerY = 112;
    let radius = 105;
    let startAngle = Math.PI;
    let endAngle = Math.PI * 2;
    let progressEndAngle = startAngle + progress * Math.PI;

    context.clearRect(0, 0, width, height);
    context.lineCap = 'round';
    context.lineJoin = 'round';

    context.beginPath();
    context.lineWidth = 15;
    context.strokeStyle = '#F1F5F9';
    context.arc(centerX, centerY, radius, startAngle, endAngle, false);
    context.stroke();

    if (progress > 0) {
      context.beginPath();
      context.lineWidth = 15;
      context.strokeStyle = '#36C79A';
      context.arc(centerX, centerY, radius, startAngle, progressEndAngle, false);
      context.stroke();
    }
  }

  @Builder
  profileHeroSection() {
    Column({ space: 18 }) {
      Row() {
        Text('\u6211\u7684')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')

        Button('\u8bbe\u7f6e')
          .height(36)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#57D6AF')
          .borderRadius(16)
          .onClick(() => {
            this.openProfilePanel('settings');
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Row({ space: 16 }) {
        Stack({ alignContent: Alignment.BottomEnd }) {
          Row() {
            Text(this.profileInitial())
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
          .width(80)
          .height(80)
          .borderRadius(40)
          .backgroundColor('#7CE5C7')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)

          Row() {
            Text('V3')
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#FFB84D')
          .borderRadius(10)
        }

        Column({ space: 8 }) {
          Text(this.profileName)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')

          Row({ space: 8 }) {
            Text(this.profileMembership)
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .backgroundColor('#57D6AF')
              .borderRadius(12)

            Text(`\u79ef\u5206 ${this.profilePoints}`)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor('#E8FFF7')
          }

          Text(this.profileEmail)
            .fontSize(12)
            .fontColor('#E8FFF7')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.profileSignature)
        .fontSize(13)
        .lineHeight(20)
        .fontColor('#E8FFF7')
        .width('100%')
    }
    .padding(24)
    .width('100%')
    .backgroundColor('#36C79A')
    .borderRadius(24)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  profileStatsSection() {
    Row({ space: 12 }) {
      this.profileStatCard('\u6570\u636e\u62a5\u544a', `${this.profileHealthScore()}`, '\u5206', '#4B8DFF', '#EEF4FF', '\u62a5', () => {
        this.openProfilePanel('weekly');
      })
      this.profileStatCard('\u4f1a\u5458\u6743\u76ca', `${this.profileBenefitCount()}`, '\u9879', '#FF9D4D', '#FFF7EE', '\u793c', () => {
        this.openProfilePanel('benefits');
      })
    }
    .width('100%')
  }

  @Builder
  profileQuickTagsSection() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        this.profileQuickTag('\u76ee\u6807', this.goalDisplayText(), '#ECFBF5', '#36C79A')
        this.profileQuickTag('\u6b65\u6570', `${this.steps}`, '#EEF4FF', '#4B8DFF')
      }
      .width('100%')

      Row({ space: 8 }) {
        this.profileQuickTag('\u4eca\u65e5\u996e\u98df', `${this.calories} kcal`, '#FFF7EE', '#FF9D4D')
        this.profileQuickTag('\u8fd0\u52a8\u6d88\u8017', `${this.exerciseCaloriesBurned} kcal`, '#F4EEFF', '#8B5CF6')
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  profileMenuSection() {
    Column({ space: 0 }) {
      ForEach(this.profileMenuItems, (item: ProfileMenuItem) => {
        this.profileMenuRow(item)
      }, (item: ProfileMenuItem) => item.id.toString())
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
  }

  @Builder
  profileLogoutSection() {
    Button('\u9000\u51fa\u767b\u5f55')
      .width('100%')
      .height(52)
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .fontColor('#EF4444')
      .backgroundColor('#FFFFFF')
      .borderRadius(24)
      .onClick(() => {
        this.logout();
      })
  }

  @Builder
  profileFooterSection() {
    Text('\u7248\u672c 2.4.0')
      .fontSize(12)
      .fontColor('#CBD5E1')
      .width('100%')
      .textAlign(TextAlign.Center)
  }

  @Builder
  profileStatCard(title: string, value: string, unit: string, tint: string, bgColor: string, glyph: string, action: () => void) {
    Column({ space: 16 }) {
      Row() {
        if (profileStatIcon(glyph) !== undefined) {
          Image(profileStatIcon(glyph))
            .width(24)
            .height(24)
            .objectFit(ImageFit.Contain)
        } else {
          Text(glyph)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(tint)
        }
      }
      .width(40)
      .height(40)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      Column({ space: 6 }) {
        Text(title)
          .fontSize(12)
          .fontColor('#94A3B8')

        Row({ space: 4 }) {
          Text(value)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0F172A')

          Text(unit)
            .fontSize(12)
            .fontColor('#94A3B8')
            .margin({ top: 8 })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .layoutWeight(1)
    .padding(18)
    .backgroundColor(bgColor)
    .borderRadius(24)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      action();
    })
  }

  @Builder
  profileQuickTag(title: string, value: string, bgColor: string, tint: string) {
    Row({ space: 10 }) {
      Row() {
        if (profileQuickTagIcon(title) !== undefined) {
          Image(profileQuickTagIcon(title))
            .width(22)
            .height(22)
            .objectFit(ImageFit.Contain)
        }
      }
      .width(38)
      .height(38)
      .backgroundColor('#FFFFFF')
      .borderRadius(14)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      Column({ space: 5 }) {
        Text(title)
          .fontSize(12)
          .fontColor('#94A3B8')

        Text(value)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(tint)
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .layoutWeight(1)
    .padding(14)
    .backgroundColor(bgColor)
    .borderRadius(18)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.handleProfileQuickTag(title);
    })
  }

  @Builder
  profileDetailSheet() {
    Column() {
      Row() {
        Row() {
          Image(profilePanelIcon(this.activeProfilePanel))
            .width(24)
            .height(24)
            .objectFit(ImageFit.Contain)
        }
          .width(40)
          .height(40)
          .backgroundColor('#F8FAFC')
          .borderRadius(14)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)

        Text(this.profilePanelTitle)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')

        Button() {
          this.closeGlyph('#94A3B8', 16, 2)
        }
          .width(40)
          .height(40)
          .backgroundColor('#FFFFFF')
          .borderRadius(20)
          .padding(0)
          .onClick(() => {
            this.closeProfilePanel();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 18 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column({ space: 16 }) {
          if (this.profileActionMessage.length > 0) {
            Text(this.profileActionMessage)
              .fontSize(12)
              .lineHeight(18)
              .fontColor('#36C79A')
              .padding(14)
              .width('100%')
              .backgroundColor('#ECFBF5')
              .borderRadius(16)
          }

          if (this.activeProfilePanel === 'settings') {
            this.profileSectionTitle('\u57fa\u7840\u8d44\u6599', '\u8c03\u6574\u4f60\u5728\u4e2a\u4eba\u4e3b\u9875\u7684\u5c55\u793a\u4fe1\u606f')
            this.authInputCard('\u6635\u79f0', '\u8f93\u5165\u6635\u79f0', this.profileNameDraft, (value: string) => {
              this.profileNameDraft = value;
              this.profileActionMessage = '';
            })
            this.authInputCard('\u4e2a\u6027\u7b7e\u540d', '\u4f8b\u5982\uff1a\u4eca\u5929\u4e5f\u8981\u7a33\u7a33\u6253\u5361', this.profileSignatureDraft, (value: string) => {
              this.profileSignatureDraft = value;
              this.profileActionMessage = '';
            })

            this.profileSectionTitle('\u63d0\u9192\u4e0e\u540c\u6b65', '\u8fd9\u4e9b\u504f\u597d\u4f1a\u5f71\u54cd\u4e2a\u4eba\u9875\u548c\u8bb0\u5f55\u4f53\u9a8c')
            this.profileToggleRow('\u6bcf\u65e5\u6253\u5361\u63d0\u9192', '\u5728\u665a\u4e0a\u63d0\u9192\u4f60\u56de\u770b\u4eca\u65e5\u8bb0\u5f55', 'notification')
            this.profileToggleRow('AI \u65e5\u62a5\u6458\u8981', '\u5728 AI \u5bf9\u8bdd\u9875\u7ed9\u4f60\u4e00\u53e5\u8f7b\u91cf\u603b\u7ed3', 'aiDigest')
            this.profileToggleRow('\u6b65\u6570\u81ea\u52a8\u540c\u6b65', '\u8fdb\u5165 App \u65f6\u81ea\u52a8\u540c\u6b65\u5f53\u65e5\u6b65\u6570', 'stepSync')
            this.profileToggleRow('\u996e\u6c34\u63d0\u9192', '\u5728\u4f60\u996e\u6c34\u504f\u5c11\u65f6\u63d0\u9192\u8865\u6c34', 'waterReminder')
          }

          if (this.activeProfilePanel === 'weekly') {
            this.profileSectionTitle('\u672c\u5468\u603b\u89c8', '\u6839\u636e\u4f60\u5f53\u524d\u7684\u8bb0\u5f55\u4e0e\u8fde\u7eed\u6253\u5361\u72b6\u6001\u751f\u6210')
            Row({ space: 12 }) {
              this.profileMetricCard('\u5065\u5eb7\u5206', `${this.profileHealthScore()}`, '\u5206', '#EEF4FF', '#4B8DFF')
              this.profileMetricCard('\u8fde\u7eed\u6253\u5361', `${this.streakDays}`, '\u5929', '#ECFBF5', '#36C79A')
            }
            .width('100%')

            Row({ space: 12 }) {
              this.profileMetricCard('\u996e\u98df\u6444\u5165', `${this.calories}`, 'kcal', '#FFF7EE', '#FF9D4D')
              this.profileMetricCard('\u8fd0\u52a8\u6d88\u8017', `${this.exerciseCaloriesBurned}`, 'kcal', '#F4EEFF', '#8B5CF6')
            }
            .width('100%')

            this.weeklyWeightChartCard()
            this.profileInsightCard('\u4f53\u91cd\u8d8b\u52bf', this.weightTrendSummary(), '#F8FAFC')
            this.profileInsightCard('\u672c\u5468\u8fdb\u5c55', this.weeklyProgressSummary(), '#F8FAFC')
            this.profileInsightCard('\u7ed9\u4f60\u7684\u5efa\u8bae', this.weeklySuggestionSummary(), '#F8FAFC')
          }

          if (this.activeProfilePanel === 'benefits') {
            this.profileSectionTitle('\u4f1a\u5458\u6743\u76ca', '\u628a\u79ef\u5206\u548c\u8fde\u7eed\u8bb0\u5f55\u53d8\u6210\u66f4\u7a33\u7684\u6fc0\u52b1')
            Row({ space: 12 }) {
              this.profileMetricCard('\u5f53\u524d\u7b49\u7ea7', this.profileMembership, '', '#FFF7EE', '#FF9D4D')
              this.profileMetricCard('\u53ef\u7528\u79ef\u5206', `${this.profilePoints}`, '\u5206', '#ECFBF5', '#36C79A')
            }
            .width('100%')

            Row({ space: 12 }) {
              this.profileMetricCard('\u4eca\u65e5\u6210\u5c31', `${this.achievementSummary().points}`, '\u5206', '#EEF4FF', '#4B8DFF')
              this.profileMetricCard('\u5907\u4efd\u8bb0\u5f55', `${this.exportDataLineCount()}`, '\u884c', '#F8FAFC', '#607184')
            }
            .width('100%')

            this.profileInsightCard('\u4eca\u65e5\u79ef\u5206\u660e\u7ec6', this.achievementLinesText(), '#ECFBF5')
            this.profileBenefitCard('\u5468\u62a5\u89e3\u8bfb', '\u6bcf\u5468\u751f\u6210\u4e00\u4efd\u996e\u98df\u3001\u4f53\u91cd\u548c\u8fd0\u52a8\u603b\u7ed3', '#EEF4FF', '#4B8DFF')
            this.profileBenefitCard('\u996e\u6c34\u63d0\u9192', '\u996e\u6c34\u504f\u5c11\u65f6\u4f1a\u5728\u8bb0\u5f55\u9875\u7ed9\u51fa\u63d0\u9192', '#E9F9FF', '#32C5F4')
            this.profileBenefitCard('AI \u5065\u5eb7\u95ee\u7b54', '\u6839\u636e\u5df2\u8bb0\u5f55\u6570\u636e\u7ed9\u51fa\u66f4\u5177\u4f53\u7684\u5efa\u8bae', '#ECFBF5', '#36C79A')
            this.profileBenefitCard('\u76ee\u6807\u8ddf\u8e2a', '\u4f53\u91cd\u53d8\u5316\u540e\u81ea\u52a8\u5237\u65b0\u5f53\u524d\u76ee\u6807\u8ddd\u79bb', '#FFF7EE', '#FF9D4D')
            this.profileInsightCard('CSV \u5907\u4efd', this.dataExportSummary(), '#F8FAFC')
          }

          if (this.activeProfilePanel === 'goal') {
            this.profileSectionTitle('\u76ee\u6807\u8bbe\u5b9a', '\u628a\u672c\u5468\u60f3\u8981\u63a8\u8fdb\u7684\u76ee\u6807\u5199\u6e05\u695a')
            this.authInputCard('\u9636\u6bb5\u76ee\u6807', '\u4f8b\u5982\uff1a\u51cf\u8102 4kg', this.profileGoalDraft, (value: string) => {
              this.profileGoalDraft = value;
              this.profileActionMessage = '';
            })
            this.authInputCard('\u6bcf\u5468\u76ee\u6807', '\u4f8b\u5982\uff1a0.3', this.profileWeeklyTargetDraft, (value: string) => {
              this.profileWeeklyTargetDraft = value;
              this.profileActionMessage = '';
            })
            this.authInputCard('\u63d0\u9192\u65f6\u95f4', '\u4f8b\u5982\uff1a21:00', this.profileReminderTimeDraft, (value: string) => {
              this.profileReminderTimeDraft = value;
              this.profileActionMessage = '';
            })
            this.profileInsightCard('\u76ee\u6807\u63cf\u8ff0', this.goalPlanPreview(), '#ECFBF5')
          }

          if (this.activeProfilePanel === 'security') {
            this.profileSectionTitle('\u8d26\u53f7\u4fe1\u606f', '\u4f60\u73b0\u5728\u4f7f\u7528\u7684\u662f\u8d26\u53f7\u5bc6\u7801\u767b\u5f55')
            this.profileInsightCard('\u5f53\u524d\u90ae\u7bb1', this.profileEmail, '#F8FAFC')
            this.profileInsightCard('\u767b\u5f55\u65b9\u5f0f', '\u672c\u5730\u8d26\u53f7', '#F8FAFC')
            this.authInputCard('\u5f53\u524d\u5bc6\u7801', '\u8f93\u5165\u5f53\u524d\u5bc6\u7801', this.securityCurrentPasswordDraft, (value: string) => {
              this.securityCurrentPasswordDraft = value;
              this.profileActionMessage = '';
            })
            this.authInputCard('\u65b0\u5bc6\u7801', '\u81f3\u5c11 6 \u4f4d', this.securityNextPasswordDraft, (value: string) => {
              this.securityNextPasswordDraft = value;
              this.profileActionMessage = '';
            })
            this.authInputCard('\u786e\u8ba4\u65b0\u5bc6\u7801', '\u518d\u8f93\u5165\u4e00\u6b21', this.securityConfirmPasswordDraft, (value: string) => {
              this.securityConfirmPasswordDraft = value;
              this.profileActionMessage = '';
            })
          }

          if (this.activeProfilePanel === 'feedback') {
            this.profileSectionTitle('\u5e2e\u52a9\u4e0e\u53cd\u9988', '\u4f60\u53ef\u4ee5\u76f4\u63a5\u53d1\u9001\u7ed9 AI \u52a9\u624b\uff0c\u4e5f\u53ef\u4ee5\u5feb\u901f\u67e5\u770b\u5e38\u7528\u5efa\u8bae')
            this.authInputCard('\u53cd\u9988\u5185\u5bb9', '\u8f93\u5165\u4f60\u60f3\u63d0\u7684\u95ee\u9898\u6216\u5efa\u8bae', this.feedbackDraft, (value: string) => {
              this.feedbackDraft = value;
              this.profileActionMessage = '';
            })
            this.profileFeedbackShortcut('\u65e0\u6cd5\u8fde\u4e0a backend', '\u5e2e\u6211\u6392\u67e5\u4e00\u4e0b\u4e3a\u4ec0\u4e48 App \u8fde\u4e0d\u4e0a backend')
            this.profileFeedbackShortcut('\u70ed\u91cf\u7edf\u8ba1\u4e0d\u5bf9', '\u5e2e\u6211\u68c0\u67e5\u4e00\u4e0b\u8bb0\u5f55\u9875\u7684\u70ed\u91cf\u7edf\u8ba1\u903b\u8f91')
            this.profileFeedbackShortcut('\u60f3\u8981\u65b0\u529f\u80fd', '\u6211\u60f3\u63d0\u4e00\u4e2a\u65b0\u529f\u80fd\u9700\u6c42')
          }
        }
        .padding({ left: 18, right: 18, top: 6, bottom: 24 })
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .width('100%')

      if (this.activeProfilePanel === 'settings') {
        this.profilePanelActionBar('\u4fdd\u5b58\u8bbe\u7f6e', () => {
          void this.saveProfileSettings();
        })
      }

      if (this.activeProfilePanel === 'goal') {
        this.profilePanelActionBar('\u4fdd\u5b58\u76ee\u6807', () => {
          void this.saveProfileGoal();
        })
      }

      if (this.activeProfilePanel === 'security') {
        this.profilePanelActionBar('\u4fee\u6539\u5bc6\u7801', () => {
          void this.saveProfilePassword();
        })
      }

      if (this.activeProfilePanel === 'feedback') {
        this.profilePanelActionBar('\u53d1\u9001\u7ed9 AI \u52a9\u624b', () => {
          this.sendProfileFeedback();
        })
      }

      if (this.activeProfilePanel === 'weekly') {
        this.profilePanelActionBar('\u8ba9 AI \u89e3\u8bfb\u8fd9\u4e2a\u5468\u62a5', () => {
          this.openWeeklyReportInAi();
        })
      }

      if (this.activeProfilePanel === 'benefits') {
        this.profilePanelActionBar('\u751f\u6210 CSV \u5907\u4efd', () => {
          this.exportHealthData();
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  profileSectionTitle(title: string, subtitle: string) {
    Column({ space: 6 }) {
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0F172A')

      Text(subtitle)
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#94A3B8')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  profileToggleRow(title: string, subtitle: string, toggleKey: string) {
    Row({ space: 12 }) {
      Column({ space: 4 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')

        Text(subtitle)
          .fontSize(12)
          .lineHeight(18)
          .fontColor('#94A3B8')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Row() {
        Text(this.profileToggleValue(toggleKey) ? '\u5df2\u5f00\u542f' : '\u5df2\u5173\u95ed')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.profileToggleValue(toggleKey) ? '#36C79A' : '#64748B')
      }
      .height(34)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.profileToggleValue(toggleKey) ? '#ECFBF5' : '#F1F5F9')
      .borderRadius(14)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F8FAFC')
    .borderRadius(18)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.toggleProfilePreference(toggleKey);
    })
  }

  @Builder
  profileMetricCard(title: string, value: string, unit: string, bgColor: string, tint: string) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(12)
        .fontColor('#94A3B8')

      Row({ space: 4 }) {
        Text(value)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(tint)

        Text(unit)
          .fontSize(12)
          .fontColor('#94A3B8')
          .margin({ top: 10 })
      }
    }
    .layoutWeight(1)
    .padding(16)
    .backgroundColor(bgColor)
    .borderRadius(18)
    .alignItems(HorizontalAlign.Start)
  }

  profileToggleValue(toggleKey: string): boolean {
    if (toggleKey === 'notification') {
      return this.profileNotificationEnabled;
    }
    if (toggleKey === 'aiDigest') {
      return this.profileAiDigestEnabled;
    }
    if (toggleKey === 'stepSync') {
      return this.profileStepSyncEnabled;
    }
    if (toggleKey === 'waterReminder') {
      return this.profileWaterReminderEnabled;
    }
    return false;
  }

  @Builder
  weeklyWeightChartCard() {
    Column({ space: 14 }) {
      Row() {
        Column({ space: 4 }) {
          Text('\u672c\u5468\u4f53\u91cd')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0F172A')

          Text(`\u6700\u65b0 ${this.weight.toFixed(2)}kg`)
            .fontSize(12)
            .fontColor('#94A3B8')
        }
        .alignItems(HorizontalAlign.Start)

        Row({ space: 4 }) {
          Text(this.weekLoss >= 0 ? '-' : '+')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.weekLoss >= 0 ? '#36C79A' : '#F97316')

          Text(Math.abs(this.weekLoss).toFixed(2))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.weekLoss >= 0 ? '#36C79A' : '#F97316')

          Text('kg')
            .fontSize(11)
            .fontColor('#94A3B8')
            .margin({ top: 6 })
        }
        .alignItems(VerticalAlign.Bottom)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Column({ space: 8 }) {
        Canvas(this.weeklyWeightChartContext)
          .width(320)
          .height(168)
          .backgroundColor('#FFFFFF')
          .onReady(() => {
            this.drawWeeklyWeightChart();
          })

        Row() {
          ForEach(this.weeklyWeightSeries(), (item: WeeklyWeightPoint) => {
            Text(item.label)
              .layoutWeight(1)
              .fontSize(11)
              .textAlign(TextAlign.Center)
              .fontColor('#94A3B8')
          }, (item: WeeklyWeightPoint) => item.label)
        }
        .width(320)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .alignItems(HorizontalAlign.Start)
    .onAppear(() => {
      this.drawWeeklyWeightChart();
    })
  }

  toggleProfilePreference(toggleKey: string): void {
    if (toggleKey === 'notification') {
      this.profileNotificationEnabled = !this.profileNotificationEnabled;
    } else if (toggleKey === 'aiDigest') {
      this.profileAiDigestEnabled = !this.profileAiDigestEnabled;
    } else if (toggleKey === 'stepSync') {
      this.profileStepSyncEnabled = !this.profileStepSyncEnabled;
    } else if (toggleKey === 'waterReminder') {
      this.profileWaterReminderEnabled = !this.profileWaterReminderEnabled;
    }
    this.profileActionMessage = '';
    this.queuePersistAppState();
  }

  @Builder
  profileInsightCard(title: string, content: string, bgColor: string) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0F172A')

      Text(content)
        .fontSize(13)
        .lineHeight(20)
        .fontColor('#475569')
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(bgColor)
    .borderRadius(18)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  profileBenefitCard(title: string, content: string, bgColor: string, tint: string) {
    Row({ space: 12 }) {
      Row() {
        this.plusGlyph(tint, 14, 2)
      }
      .width(36)
      .height(36)
      .backgroundColor('#FFFFFF')
      .borderRadius(14)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      Column({ space: 5 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')

        Text(content)
          .fontSize(12)
          .lineHeight(18)
          .fontColor('#64748B')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(bgColor)
    .borderRadius(18)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  profileFeedbackShortcut(title: string, message: string) {
    Button(title)
      .width('100%')
      .height(44)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor('#475569')
      .backgroundColor('#F8FAFC')
      .borderRadius(16)
      .onClick(() => {
        this.feedbackDraft = message;
        this.profileActionMessage = '\u5df2\u586b\u5145\u5feb\u6377\u53cd\u9988\uff0c\u53ef\u4ee5\u76f4\u63a5\u53d1\u9001';
      })
  }

  @Builder
  profilePanelActionBar(title: string, action: () => void) {
    Column() {
      Button(title)
        .width('100%')
        .height(52)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor('#36C79A')
        .borderRadius(18)
        .onClick(() => {
          action();
        })
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 12, bottom: 26 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  profileMenuRow(item: ProfileMenuItem) {
    Row({ space: 14 }) {
      Row() {
        if (profileMenuIcon(item.id) !== undefined) {
          Image(profileMenuIcon(item.id))
            .width(24)
            .height(24)
            .objectFit(ImageFit.Contain)
        } else {
          Text(item.glyph)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(item.tint)
        }
      }
      .width(44)
      .height(44)
      .backgroundColor(item.bgColor)
      .borderRadius(16)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      Column({ space: 4 }) {
        Text(item.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')

        Text(this.profileMenuSubtitle(item))
          .fontSize(12)
          .lineHeight(18)
          .fontColor('#94A3B8')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Row({ space: 8 }) {
        if (item.badge.length > 0) {
          Text(item.badge)
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .padding({ left: 6, right: 6, top: 4, bottom: 4 })
            .backgroundColor('#F97316')
            .borderRadius(10)
        }

        Image($r('app.media.icon_chevron_right'))
          .width(16)
          .height(16)
          .objectFit(ImageFit.Contain)
      }
      .alignItems(VerticalAlign.Center)
    }
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .width('100%')
    .border({
      width: { bottom: item.id === this.profileMenuItems.length ? 0 : 1 },
      color: { bottom: '#F1F5F9' }
    })
    .onClick(() => {
      this.handleProfileMenu(item);
    })
  }

  openWeightInput(): void {
    this.ensureDailyHealthStateCurrent();
    this.weightDraftUnit = 'kg';
    this.weightDraft = this.weight.toFixed(2);
    this.weightInputTime = this.currentClock();
    this.weightInputError = '';
    this.showWeightRuler = false;
    this.isWeightInputOpen = true;
  }

  closeWeightInput(): void {
    this.isWeightInputOpen = false;
    this.weightInputError = '';
  }

  isWeightDraftValid(value: string): boolean {
    return /^\d*\.?\d{0,2}$/.test(value);
  }

  switchWeightUnit(unit: 'kg' | 'jin'): void {
    if (this.weightDraftUnit === unit) {
      return;
    }

    let currentWeightKg: number = this.weightDraftToKg();
    this.weightDraftUnit = unit;
    this.weightDraft = this.displayWeightDraft(currentWeightKg);
    this.weightInputError = '';
  }

  adjustWeightDraft(deltaKg: number): void {
    let nextWeightKg: number = this.clampWeightKg(this.weightDraftToKg() + deltaKg);
    this.weightDraft = this.displayWeightDraft(nextWeightKg);
    this.weightInputError = '';
  }

  weightDraftDisplayValue(): number {
    let parsed: number = Number(this.weightDraft);
    if (Number.isNaN(parsed) || parsed <= 0) {
      return this.weightDraftUnit === 'jin' ? this.weight * 2 : this.weight;
    }
    return parsed;
  }

  weightDisplayMin(): number {
    return this.weightDraftUnit === 'jin' ? 60 : 30;
  }

  weightDisplayMax(): number {
    return this.weightDraftUnit === 'jin' ? 300 : 150;
  }

  weightDisplayStep(): number {
    return this.weightDraftUnit === 'jin' ? 0.2 : 0.1;
  }

  updateWeightDraftFromDisplay(value: number): void {
    this.weightDraft = value.toFixed(2);
    this.weightInputError = '';
  }

  weightRulerTicks(): number[] {
    return [
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
      10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
      20, 21, 22, 23, 24
    ];
  }

  weightTickHeight(index: number): number {
    if (index === 0 || index === 12 || index === 24) {
      return 30;
    }
    if (index === 6 || index === 18) {
      return 22;
    }
    return 14;
  }

  weightTickColor(index: number): string {
    if (index === 0 || index === 12 || index === 24) {
      return '#36C79A';
    }
    if (index === 6 || index === 18) {
      return '#79DFC0';
    }
    return '#B8F0DE';
  }

  weightTickLabel(index: number): string {
    if (index === 0) {
      return this.weightDraftUnit === 'jin' ? '60' : '30';
    }
    if (index === 12) {
      return this.weightDraftUnit === 'jin' ? '180' : '90';
    }
    if (index === 24) {
      return this.weightDraftUnit === 'jin' ? '300' : '150';
    }
    return '';
  }

  displayWeightDraft(weightKg: number): string {
    return formatWeightDraft(weightKg, this.weightDraftUnit);
  }

  weightDraftToKg(): number {
    return parseWeightDraftToKg(this.weightDraft, this.weightDraftUnit, this.weight);
  }

  clampWeightKg(weightKg: number): number {
    return clampPlanWeightKg(weightKg);
  }

  saveWeightInput(): void {
    let parsed: number = Number(this.weightDraft);
    if (Number.isNaN(parsed) || parsed <= 0) {
      this.weightInputError = '\u8bf7\u8f93\u5165\u6709\u6548\u7684\u4f53\u91cd\u6570\u503c';
      return;
    }

    let nextWeight: number = this.clampWeightKg(this.weightDraftToKg());
    this.weight = nextWeight;
    this.onboardingCurrentWeight = nextWeight.toFixed(1);
    this.weightUpdateTime = this.currentClock();
    this.weightInputError = '';
    this.isWeightInputOpen = false;
    this.upsertWeightRecord(nextWeight, this.weightUpdateTime);
    this.recalculateWeightMetrics();
    this.awardPoints(4);
    this.drawWeightArc();
    this.refreshRecordModuleKeepingScroll();
    if (this.activeProfilePanel === 'weekly') {
      this.drawWeeklyWeightChart();
    }
    this.queuePersistAppState();
  }

  checkIn(): void {
    this.ensureDailyHealthStateCurrent();
    let todayKey: string = this.currentDayKey();
    if (this.lastCheckInDayKey === todayKey) {
      this.checkedToday = true;
      return;
    }

    if (this.lastCheckInDayKey === this.dayKeyFromOffset(-1)) {
      this.streakDays += 1;
    } else {
      this.streakDays = 1;
    }

    this.activeHealthDayKey = todayKey;
    this.lastCheckInDayKey = todayKey;
    this.checkedToday = true;
    this.totalCheckIns += 1;
    this.awardPoints(5);
    this.queuePersistAppState();
  }

  async startFoodScan(): Promise<void> {
    this.ensureDailyHealthStateCurrent();
    if (this.isScanningFood) {
      return;
    }

    try {
      let photoUri: string = await this.pickFoodPhoto();
      if (photoUri.length === 0) {
        return;
      }

      this.scannedImageUri = photoUri;
      this.foodScanStatus = '\u6b63\u5728\u8bfb\u53d6\u7167\u7247...';
      this.isScanningFood = true;

      let base64Image: string = await this.convertImageUriToBase64(photoUri);
      let imageMimeType: string = this.detectImageMimeType(photoUri);
      this.foodScanStatus = '\u6b63\u5728\u8ba1\u7b97\u98df\u7269\u70ed\u91cf...';

      let result: FoodRecognitionResult = await doubaoVisionService.analyzeFoodImage(base64Image, imageMimeType);
      this.lastScannedFood = result.foodName;
      this.lastScannedCalories = result.estimatedCalories;
      this.lastScannedSummary = result.summary;
      this.lastScannedAssignedMeal = '';
    } catch (error) {
      this.lastScannedFood = '\u8bc6\u522b\u5931\u8d25';
      this.lastScannedCalories = 0;
      this.lastScannedSummary = this.errorMessage(error);
      this.lastScannedAssignedMeal = '';
    } finally {
      this.foodScanStatus = 'AI \u89c6\u89c9\u8bc6\u522b\u4e2d...';
      this.isScanningFood = false;
      this.queuePersistAppState();
    }
  }

  sendFromQuickAsk(): void {
    let content: string = this.askInput.trim();
    if (content.length === 0 || this.isRequesting) {
      return;
    }
    this.askInput = '';
    this.currentTab = 1;
    this.tabsController.changeIndex(1);
    this.submitQuestion(content);
  }

  sendSuggestedQuestion(label: string): void {
    let content: string = label.trim();
    if (content.length === 0) {
      return;
    }
    if (content === WEEKLY_REPORT_LABEL) {
      this.openWeeklyReportInAi();
      return;
    }
    if (this.isRequesting) {
      this.chatInput = content;
      return;
    }
    this.chatInput = '';
    this.submitQuestion(content);
  }

  sendCurrentMessage(): void {
    let content: string = this.chatInput.trim();
    if (content.length === 0 || this.isRequesting) {
      return;
    }
    this.chatInput = '';
    this.submitQuestion(content);
  }

  clearAiConversation(): void {
    this.chatInput = '';
    this.askInput = '';
    let defaultMessages: ChatMessage[] = createDefaultMessages();
    defaultMessages[0].id = Date.now();
    this.messages = defaultMessages;
    this.queuePersistAppState();
  }

  submitQuestion(content: string): void {
    let stableMessages: ChatMessage[] = this.messagesForModel(this.messages);
    let requestId: number = Date.now();
    let userMessage: ChatMessage = {
      id: requestId,
      role: 'user',
      content: content
    };
    let thinkingMessage: ChatMessage = {
      id: requestId + 1,
      role: 'assistant',
      content: '\u601d\u8003\u4e2d...',
      isThinking: true
    };
    let nextMessages: ChatMessage[] = [...stableMessages, userMessage, thinkingMessage];
    this.messages = nextMessages;
    this.isRequesting = true;
    this.queuePersistAppState();

    deepSeekService.chat(this.buildDeepSeekMessages([...stableMessages, userMessage]))
      .then((reply: string) => {
        this.replaceThinkingMessageById(thinkingMessage.id, reply, false);
      })
      .catch((error: Error) => {
        this.replaceThinkingMessageById(thinkingMessage.id, `\u8fde\u63a5 DeepSeek \u5931\u8d25\uff1a${error.message}\u3002`, true);
      })
      .finally(() => {
        this.isRequesting = false;
      });
  }

  messagesForModel(history: ChatMessage[]): ChatMessage[] {
    let nextHistory: ChatMessage[] = [];
    for (let index = 0; index < history.length; index++) {
      if (history[index].isThinking !== true) {
        nextHistory.push(history[index]);
      }
    }
    return nextHistory;
  }

  replaceThinkingMessageById(thinkingId: number, content: string, isError: boolean): void {
    let nextMessages: ChatMessage[] = [];
    let replaced: boolean = false;
    let nextAssistantMessageId: number = Date.now() + (isError ? 2 : 1);

    for (let index = 0; index < this.messages.length; index++) {
      let message: ChatMessage = this.messages[index];
      if (!replaced && message.id === thinkingId) {
        nextMessages.push({
          id: nextAssistantMessageId,
          role: 'assistant',
          content: content
        });
        replaced = true;
      } else {
        nextMessages.push(message);
      }
    }

    if (!replaced) {
      nextMessages.push({
        id: nextAssistantMessageId,
        role: 'assistant',
        content: content
      });
    }

    this.messages = nextMessages;
    this.queuePersistAppState();
  }

  buildDeepSeekMessages(history: ChatMessage[]): DeepSeekMessage[] {
    let systemMessage: DeepSeekMessage = {
      role: 'system',
      content: `You are a helpful health assistant for a HarmonyOS app. Answer in concise Chinese by default. Current user metrics: weight ${this.weight.toFixed(2)} kg, calories ${this.calories} kcal, water ${this.water} ml, steps ${this.steps}, streak ${this.streakDays} days, weekly weight change ${this.weekLoss.toFixed(2)} kg, goal pace ${this.goalAdjustment().paceText}. Use meal, water, exercise, weight, reminders, and goal adjustment records when relevant.`
    };
    let conversation: DeepSeekMessage[] = [];
    history.slice(-8).forEach((message: ChatMessage) => {
      let mappedMessage: DeepSeekMessage = {
        role: message.role,
        content: message.content
      };
      conversation.push(mappedMessage);
    });
    return [systemMessage, ...conversation];
  }

  switchAuthMode(mode: AuthMode): void {
    this.authMode = mode;
    this.authError = '';
    if (mode === 'login') {
      this.authHint = '\u53ef\u4ee5\u4f7f\u7528\u6f14\u793a\u8d26\u53f7\u4f53\u9a8c\uff0c\u4e5f\u53ef\u4ee5\u767b\u5f55\u4f60\u521a\u6ce8\u518c\u7684\u8d26\u53f7';
    } else {
      this.authHint = '\u6ce8\u518c\u540e\u4f1a\u76f4\u63a5\u66f4\u65b0\u4f60\u7684\u4e2a\u4eba\u4fe1\u606f\uff0c\u968f\u540e\u53ef\u4ee5\u7ee7\u7eed\u767b\u5f55\u4f7f\u7528';
    }
  }

  useDemoAccount(): void {
    if (this.isAuthSubmitting) {
      return;
    }
    this.authMode = 'login';
    this.loginEmail = this.demoAccountEmail;
    this.loginPassword = this.demoAccountPassword;
    this.authError = '';
    this.authHint = '\u5df2\u586b\u5145\u6f14\u793a\u8d26\u53f7\uff0c\u70b9\u51fb\u201c\u7acb\u5373\u767b\u5f55\u201d\u5373\u53ef\u5411\u670d\u52a1\u7aef\u9a8c\u8bc1\u5e76\u8fdb\u5165';
  }

  async submitLogin(): Promise<void> {
    if (this.isAuthSubmitting) {
      return;
    }

    let email: string = this.loginEmail.trim();
    let password: string = this.loginPassword.trim();
    if (email.length === 0 || password.length === 0) {
      this.authError = '\u8bf7\u5148\u8f93\u5165\u5b8c\u6574\u7684\u90ae\u7bb1\u548c\u5bc6\u7801';
      return;
    }

    this.isAuthSubmitting = true;
    this.authError = '';
    this.authHint = '\u6b63\u5728\u8fde\u63a5\u670d\u52a1\u7aef\u9a8c\u8bc1\u8d26\u53f7...';

    try {
      const response = await authService.login(email, password);
      if (!response.user || !response.token) {
        this.authError = '\u767b\u5f55\u5931\u8d25\uff0c\u670d\u52a1\u7aef\u672a\u8fd4\u56de\u5b8c\u6574\u7684\u8d26\u53f7\u4fe1\u606f';
        return;
      }

      let shouldResetLocalData: boolean = !this.canReuseLocalStateForUser(email);
      this.authToken = response.token;
      this.applyAuthUser(response.user);
      if (!this.needsOnboarding && shouldResetLocalData) {
        this.applyUserMetrics(response.user);
      }
      this.currentTab = 0;
      this.tabsController.changeIndex(0);
      this.isAuthenticated = true;
      this.loginEmail = email;
      this.loginPassword = '';
      this.authHint = this.needsOnboarding
        ? '\u8bf7\u5148\u5b8c\u6210\u57fa\u7840\u4fe1\u606f\u521d\u59cb\u5316'
        : '\u6b22\u8fce\u56de\u6765';
      this.queuePersistAppState();
      await this.restoreRemoteStateIfNeeded();
    } catch (error) {
      let message: string = this.authErrorMessage(error);
      if (this.isDemoCredential(email, password) && this.canUseOfflineDemo(message)) {
        this.applyOfflineDemoLogin();
        return;
      }
      this.authError = message;
      this.authHint = '\u767b\u5f55\u5931\u8d25\uff0c\u8bf7\u786e\u8ba4\u540e\u7aef\u5df2\u542f\u52a8\u4e14\u8d26\u53f7\u5bc6\u7801\u6b63\u786e';
    } finally {
      this.isAuthSubmitting = false;
    }
  }

  async submitRegister(): Promise<void> {
    if (this.isAuthSubmitting) {
      return;
    }

    let name: string = this.registerName.trim();
    let email: string = this.registerEmail.trim();
    let password: string = this.registerPassword.trim();
    let confirmPassword: string = this.registerConfirmPassword.trim();

    if (name.length === 0 || email.length === 0 || password.length === 0 || confirmPassword.length === 0) {
      this.authError = '\u8bf7\u628a\u6ce8\u518c\u4fe1\u606f\u586b\u5199\u5b8c\u6574';
      return;
    }
    if (password.length < 6) {
      this.authError = '\u5bc6\u7801\u957f\u5ea6\u81f3\u5c11 6 \u4f4d';
      return;
    }
    if (password !== confirmPassword) {
      this.authError = '\u4e24\u6b21\u8f93\u5165\u7684\u5bc6\u7801\u4e0d\u4e00\u81f4';
      return;
    }

    this.isAuthSubmitting = true;
    this.authError = '';
    this.authHint = '\u6b63\u5728\u521b\u5efa\u670d\u52a1\u7aef\u8d26\u53f7...';

    try {
      const response = await authService.register(name, email, password);
      if (response.user) {
        this.applyAuthUser(response.user);
      }
      this.loginEmail = email;
      this.loginPassword = password;
      this.profilePassword = '';
      this.registerName = '';
      this.registerEmail = '';
      this.registerPassword = '';
      this.registerConfirmPassword = '';
      this.authMode = 'login';
      this.authError = '';
      this.authHint = response.message && response.message.length > 0
        ? `${response.message}\uff0c\u767b\u5f55\u540e\u9700\u8981\u5148\u5b8c\u6210\u57fa\u7840\u4fe1\u606f\u521d\u59cb\u5316`
        : '\u6ce8\u518c\u6210\u529f\uff0c\u767b\u5f55\u540e\u9700\u8981\u5148\u5b8c\u6210\u57fa\u7840\u4fe1\u606f\u521d\u59cb\u5316';
      this.queuePersistAppState();
    } catch (error) {
      this.authError = this.authErrorMessage(error);
      this.authHint = '\u6ce8\u518c\u5931\u8d25\uff0c\u8bf7\u786e\u8ba4\u540e\u7aef\u5df2\u542f\u52a8\u4e14\u90ae\u7bb1\u5c1a\u672a\u88ab\u6ce8\u518c';
    } finally {
      this.isAuthSubmitting = false;
    }
  }

  async submitOnboarding(): Promise<void> {
    if (this.isOnboardingSubmitting) {
      return;
    }

    let name: string = this.onboardingName.trim();
    let gender: string = this.onboardingGender.trim();
    let age: number = Number(this.onboardingAge);
    let heightCm: number = Number(this.onboardingHeight);
    let currentWeightKg: number = Number(this.onboardingCurrentWeight);
    let targetWeightKg: number = Number(this.onboardingTargetWeight);
    let weeklyTargetKg: number = Number(this.onboardingWeeklyTarget);

    if (name.length === 0 || gender.length === 0 || this.onboardingAge.trim().length === 0
      || this.onboardingHeight.trim().length === 0 || this.onboardingCurrentWeight.trim().length === 0
      || this.onboardingTargetWeight.trim().length === 0 || this.onboardingWeeklyTarget.trim().length === 0) {
      this.onboardingError = '\u8bf7\u5148\u628a\u57fa\u7840\u4fe1\u606f\u586b\u5199\u5b8c\u6574';
      return;
    }

    this.isOnboardingSubmitting = true;
    this.onboardingError = '';

    try {
      const response = await authService.completeOnboarding(this.authToken, this.profileEmail, name, gender, age, heightCm,
        currentWeightKg, targetWeightKg, weeklyTargetKg);
      if (!response.user) {
        this.onboardingError = '\u521d\u59cb\u5316\u5931\u8d25\uff0c\u670d\u52a1\u7aef\u672a\u8fd4\u56de\u7528\u6237\u4fe1\u606f';
        return;
      }
      this.applyAuthUser(response.user);
      this.applyUserMetrics(response.user);
      this.authHint = '\u521d\u59cb\u5316\u5b8c\u6210\uff0c\u73b0\u5728\u53ef\u4ee5\u5f00\u59cb\u8bb0\u5f55\u4e86';
      this.queuePersistAppState();
      await this.syncRemoteStateToServer();
    } catch (error) {
      this.onboardingError = this.authErrorMessage(error);
    } finally {
      this.isOnboardingSubmitting = false;
    }
  }

  logout(): void {
    this.closeProfilePanel();
    this.authToken = '';
    this.authProvider = 'local';
    this.needsOnboarding = false;
    this.isOnboardingSubmitting = false;
    this.onboardingError = '';
    this.currentTab = 0;
    this.tabsController.changeIndex(0);
    this.isAuthenticated = false;
    this.switchAuthMode('login');
    this.loginEmail = '';
    this.loginPassword = '';
    this.authHint = '\u5df2\u9000\u51fa\u5f53\u524d\u8d26\u53f7';
    this.clearRemoteSyncTimer();
    this.queuePersistAppState();
  }

  applyAuthUser(user: AuthUser): void {
    this.profileName = user.name;
    this.profileEmail = user.email;
    this.profileMembership = user.membership;
    this.profilePoints = user.points;
    this.profileGoalText = user.goalText;
    this.profileSignature = user.signature;
    this.profileNameDraft = user.name;
    this.profileGoalDraft = user.goalText;
    this.profileSignatureDraft = user.signature;
    this.authProvider = user.provider;
    this.profilePassword = '';
    this.onboardingName = user.name;
    this.onboardingGender = user.gender;
    this.onboardingAge = user.age > 0 ? `${user.age}` : '';
    this.onboardingHeight = user.heightCm > 0 ? `${user.heightCm}` : '';
    this.onboardingCurrentWeight = user.currentWeightKg > 0 ? user.currentWeightKg.toFixed(1) : '';
    this.onboardingTargetWeight = user.targetWeightKg > 0 ? user.targetWeightKg.toFixed(1) : '';
    this.onboardingWeeklyTarget = user.weeklyTargetKg > 0 ? user.weeklyTargetKg.toFixed(1) : '0.3';
    this.needsOnboarding = !user.onboardingCompleted;
    this.onboardingError = '';
    this.queuePersistAppState();
  }

  applyUserMetrics(user: AuthUser): void {
    if (user.email === this.demoAccountEmail) {
      return;
    }

    let initialWeight: number = user.currentWeightKg > 0 ? user.currentWeightKg : 60;
    this.weight = initialWeight;
    this.weightDraft = initialWeight.toFixed(2);
    this.weightDraftUnit = 'kg';
    this.weekLoss = 0;
    this.activeHealthDayKey = this.currentDayKey();
    this.lastCheckInDayKey = '';
    this.weightUpdateTime = this.currentClock();
    this.weightInputTime = this.weightUpdateTime;
    this.weightRecords = [this.createWeightRecord(initialWeight, this.weightUpdateTime, this.currentDayKey())];
    this.selectedTrendDayKey = this.currentDayKey();

    this.calories = 0;
    this.breakfastCalories = 0;
    this.lunchCalories = 0;
    this.dinnerCalories = 0;
    this.snackCalories = 0;
    this.water = 0;
    this.waterRecords = [];
    this.steps = 0;
    this.exerciseCaloriesBurned = 0;
    this.checkedToday = false;
    this.totalCheckIns = 0;
    this.streakDays = 0;
    this.mealRecords = [];
    this.exerciseRecords = [];
    this.foodFavorites = [];
    this.scannedImageUri = '';
    this.lastScannedFood = '';
    this.lastScannedCalories = 0;
    this.lastScannedSummary = '';
    this.lastScannedAssignedMeal = '';
    this.scannedCaloriesTotal = 0;
    this.activeMealType = 'breakfast';
    this.activeExerciseCategory = '\u70ed\u95e8';
    this.selectedExerciseId = -1;
    this.exerciseDurationDraft = '';
    this.askInput = '';
    this.chatInput = '';
    this.messages = createDefaultMessages();
    this.syncWaterIntake();
    this.recalculateWeightMetrics();
    this.drawWeightArc();
    this.drawWeeklyWeightChart();
    this.queuePersistAppState();
  }

  canReuseLocalStateForUser(email: string): boolean {
    return this.profileEmail === email && (
      this.weightRecords.length > 0
      || this.mealRecords.length > 0
      || this.exerciseRecords.length > 0
      || this.messagesForModel(this.messages).length > 1
      || this.totalCheckIns > 0
    );
  }

  isDemoCredential(email: string, password: string): boolean {
    return email === this.demoAccountEmail && password === this.demoAccountPassword;
  }

  canUseOfflineDemo(message: string): boolean {
    return message.includes('\u65e0\u6cd5\u8fde\u63a5')
      || message.includes('timeout')
      || message.includes('Time out')
      || message.includes('ECONNREFUSED')
      || message.includes('Network')
      || message.includes('Unable to resolve host');
  }

  applyOfflineDemoLogin(): void {
    let offlineDemoUser: AuthUser = {
      id: 'offline-demo',
      name: '\u5c0f\u660e',
      email: this.demoAccountEmail,
      membership: '\u767d\u91d1\u4f1a\u5458',
      points: 1200,
      goalText: '\u51cf\u8102 4kg',
      signature: '\u5df2\u8fdb\u5165\u79bb\u7ebf\u6f14\u793a\u6a21\u5f0f\uff0cAI \u804a\u5929\u3001\u8bc6\u56fe\u548c\u98df\u7269\u5e93\u9700\u8981\u542f\u52a8 backend \u540e\u624d\u80fd\u4f7f\u7528',
      provider: 'local',
      onboardingCompleted: true,
      gender: '\u5973',
      age: 24,
      heightCm: 165,
      currentWeightKg: 61.9,
      targetWeightKg: 57.9,
      weeklyTargetKg: 0.3
    };
    this.authToken = 'offline-demo-token';
    this.applyAuthUser(offlineDemoUser);
    this.currentTab = 0;
    this.tabsController.changeIndex(0);
    this.isAuthenticated = true;
    this.loginEmail = this.demoAccountEmail;
    this.loginPassword = '';
    this.authError = '';
    this.authHint = '\u5f53\u524d\u672a\u8fde\u4e0a backend\uff0c\u5df2\u81ea\u52a8\u5207\u6362\u4e3a\u79bb\u7ebf\u6f14\u793a\u6a21\u5f0f';
    this.queuePersistAppState();
  }

  openProfilePanel(panel: ProfilePanelType): void {
    this.activeProfilePanel = panel;
    this.profileActionMessage = '';
    this.profileNameDraft = this.profileName;
    this.profileGoalDraft = this.goalDisplayText();
    this.profileSignatureDraft = this.profileSignature;
    this.profileWeeklyTargetDraft = this.weeklyGoalValueText();
    this.profileReminderTimeDraft = '21:00';
    this.securityCurrentPasswordDraft = '';
    this.securityNextPasswordDraft = '';
    this.securityConfirmPasswordDraft = '';
    if (panel === 'settings') {
      this.profilePanelTitle = '\u8bbe\u7f6e';
      return;
    }
    if (panel === 'weekly') {
      this.profilePanelTitle = '\u5468\u62a5\u5206\u6790';
      this.drawWeeklyWeightChart();
      return;
    }
    if (panel === 'goal') {
      this.profilePanelTitle = '\u6211\u7684\u76ee\u6807';
      return;
    }
    if (panel === 'security') {
      this.profilePanelTitle = '\u8d26\u53f7\u5b89\u5168';
      return;
    }
    if (panel === 'benefits') {
      this.profilePanelTitle = '\u4f1a\u5458\u6743\u76ca';
      return;
    }
    this.profilePanelTitle = '\u5e2e\u52a9\u4e0e\u53cd\u9988';
  }

  closeProfilePanel(): void {
    this.activeProfilePanel = 'none';
    this.profilePanelTitle = '';
    this.profileActionMessage = '';
  }

  async saveProfileSettings(): Promise<void> {
    let name: string = this.profileNameDraft.trim();
    let signature: string = this.profileSignatureDraft.trim();
    if (name.length === 0 || signature.length === 0) {
      this.profileActionMessage = '\u6635\u79f0\u548c\u4e2a\u6027\u7b7e\u540d\u90fd\u9700\u8981\u586b\u5199';
      return;
    }

    try {
      const response = await authService.updateProfile(this.authToken, this.profileEmail, name, this.goalDisplayText(), signature);
      if (response.user) {
        this.applyAuthUser(response.user);
      }
      this.profileActionMessage = '\u4e2a\u4eba\u4fe1\u606f\u5df2\u4fdd\u5b58';
      this.queuePersistAppState();
    } catch (error) {
      this.profileActionMessage = this.authErrorMessage(error);
    }
  }

  async saveProfileGoal(): Promise<void> {
    let goalText: string = this.profileGoalDraft.trim();
    let weeklyTarget: string = this.profileWeeklyTargetDraft.trim();
    let reminderTime: string = this.profileReminderTimeDraft.trim();
    if (goalText.length === 0 || weeklyTarget.length === 0 || reminderTime.length === 0) {
      this.profileActionMessage = '\u8bf7\u628a\u76ee\u6807\u4fe1\u606f\u586b\u5199\u5b8c\u6574';
      return;
    }

    let signature: string = `\u672c\u5468\u76ee\u6807\uff1a\u6bcf\u5468\u7a33\u5b9a\u8fdb\u5c55 ${weeklyTarget}kg\uff0c${reminderTime} \u63d0\u9192\u56de\u770b`;
    try {
      const response = await authService.updateProfile(this.authToken, this.profileEmail, this.profileName, goalText, signature);
      if (response.user) {
        this.applyAuthUser(response.user);
      }
      this.profileActionMessage = '\u76ee\u6807\u8bbe\u5b9a\u5df2\u66f4\u65b0';
      this.queuePersistAppState();
    } catch (error) {
      this.profileActionMessage = this.authErrorMessage(error);
    }
  }

  async saveProfilePassword(): Promise<void> {
    let currentPassword: string = this.securityCurrentPasswordDraft.trim();
    let nextPassword: string = this.securityNextPasswordDraft.trim();
    let confirmPassword: string = this.securityConfirmPasswordDraft.trim();
    if (currentPassword.length === 0 || nextPassword.length === 0 || confirmPassword.length === 0) {
      this.profileActionMessage = '\u8bf7\u628a\u5bc6\u7801\u4fe1\u606f\u586b\u5199\u5b8c\u6574';
      return;
    }
    if (nextPassword !== confirmPassword) {
      this.profileActionMessage = '\u4e24\u6b21\u8f93\u5165\u7684\u65b0\u5bc6\u7801\u4e0d\u4e00\u81f4';
      return;
    }

    try {
      const response = await authService.changePassword(this.authToken, this.profileEmail, currentPassword, nextPassword);
      this.securityCurrentPasswordDraft = '';
      this.securityNextPasswordDraft = '';
      this.securityConfirmPasswordDraft = '';
      this.profileActionMessage = response.message && response.message.length > 0
        ? response.message
        : '\u5bc6\u7801\u4fee\u6539\u6210\u529f';
      this.queuePersistAppState();
    } catch (error) {
      this.profileActionMessage = this.authErrorMessage(error);
    }
  }

  sendProfileFeedback(): void {
    let content: string = this.feedbackDraft.trim();
    if (content.length === 0) {
      this.profileActionMessage = '\u8bf7\u5148\u5199\u4e0b\u4f60\u7684\u95ee\u9898\u6216\u5efa\u8bae';
      return;
    }
    if (this.isRequesting) {
      this.profileActionMessage = '\u5f53\u524d AI \u8fd8\u5728\u56de\u590d\u4e0a\u4e00\u6761\u6d88\u606f\uff0c\u7a0d\u7b49\u4e00\u4e0b\u518d\u53d1\u9001';
      return;
    }
    this.feedbackDraft = '';
    this.closeProfilePanel();
    this.currentTab = 1;
    this.tabsController.changeIndex(1);
    this.submitQuestion(content);
    this.authHint = '\u5df2\u628a\u4f60\u7684\u53cd\u9988\u5e26\u5230 AI \u5bf9\u8bdd\u9875\uff0c\u53ef\u4ee5\u7ee7\u7eed\u8ffd\u95ee';
  }

  openWeeklyReportInAi(): void {
    if (this.isRequesting) {
      this.profileActionMessage = '\u5f53\u524d AI \u8fd8\u5728\u56de\u590d\u4e0a\u4e00\u6761\u6d88\u606f\uff0c\u7a0d\u7b49\u4e00\u4e0b\u518d\u89e3\u8bfb\u5468\u62a5';
      return;
    }
    this.closeProfilePanel();
    this.currentTab = 1;
    this.tabsController.changeIndex(1);
    this.submitQuestion(`\u8bf7\u751f\u6210\u4e00\u4efd\u672c\u5468 AI \u5065\u5eb7\u5468\u62a5\uff0c\u5206\u4e3a\u201c\u505a\u5f97\u597d\u7684\u5730\u65b9\u201d\u201c\u9700\u8981\u6ce8\u610f\u7684\u98ce\u9669\u201d\u201c\u4e0b\u5468\u76ee\u6807\u201d\u4e09\u6bb5\u3002\u6570\u636e\uff1a\u4f53\u91cd ${this.weight.toFixed(2)}kg\uff0c\u672c\u5468\u53d8\u5316 ${this.weekLoss.toFixed(2)}kg\uff0c\u6b65\u6570 ${this.steps}\uff0c\u996e\u98df ${this.calories}kcal\uff0c\u996e\u6c34 ${this.water}ml\uff0c\u8fd0\u52a8\u6d88\u8017 ${this.exerciseCaloriesBurned}kcal\uff0c\u8fde\u7eed\u6253\u5361 ${this.streakDays} \u5929\uff0c\u76ee\u6807\u8282\u594f ${this.goalAdjustment().paceText}\u3002`);
  }

  refreshBenefitStatus(): void {
    this.profilePoints += 5;
    this.profileActionMessage = '\u6743\u76ca\u72b6\u6001\u5df2\u5237\u65b0\uff0c\u5df2\u5956\u52b1 5 \u79ef\u5206';
    this.queuePersistAppState();
  }

  profileHealthScore(): number {
    return getProfileHealthScore(this.steps, this.exerciseCaloriesBurned, this.water, this.streakDays);
  }

  profileBenefitCount(): number {
    return getProfileBenefitCount(this.profileNotificationEnabled, this.profileAiDigestEnabled,
      this.profileStepSyncEnabled, this.profileWaterReminderEnabled);
  }

  createWeightRecord(value: number, time: string, dayKey: string): WeightRecordItem {
    return {
      id: Date.now(),
      value: Number(value.toFixed(2)),
      time: time,
      dayKey: dayKey
    };
  }

  upsertWeightRecord(value: number, time: string): void {
    let dayKey: string = this.currentDayKey();
    this.weightRecords = upsertWeightRecordKeepingBaseline(this.weightRecords,
      this.createWeightRecord(value, time, dayKey));
  }

  weekStartWeight(): number {
    let keys: string[] = this.currentWeekDayKeys();
    for (let index = 0; index < keys.length; index++) {
      let startWeight: number = firstWeightForDay(this.weightRecords, keys[index]);
      if (startWeight > 0) {
        return startWeight;
      }
    }
    return this.weight;
  }

  recalculateWeightMetrics(): void {
    let nextWeekLoss: number = calculateWeekLoss(this.weightRecords, this.weight, this.currentWeekDayKeys());
    this.weekLoss = nextWeekLoss !== 0 ? nextWeekLoss : Number((this.weekStartWeight() - this.weight).toFixed(2));
  }

  weeklyWeightSeries(): WeeklyWeightPoint[] {
    let dayLabels: string[] = ['\u4e00', '\u4e8c', '\u4e09', '\u56db', '\u4e94', '\u516d', '\u65e5'];
    let dayKeys: string[] = this.currentWeekDayKeys();
    let series: WeeklyWeightPoint[] = [];
    let fallbackWeight: number = this.weekStartWeight();

    for (let index = 0; index < dayKeys.length; index++) {
      let weightValue: number = fallbackWeight;
      let latestWeight: number = latestWeightForDay(this.weightRecords, dayKeys[index]);
      if (latestWeight > 0) {
        weightValue = latestWeight;
        fallbackWeight = weightValue;
      }
      series.push({
        label: dayLabels[index],
        value: Number(weightValue.toFixed(2))
      });
    }
    return series;
  }

  drawWeeklyWeightChart(): void {
    let context = this.weeklyWeightChartContext;
    let chartWidth = 320;
    let chartHeight = 168;
    let paddingLeft = 10;
    let paddingRight = 10;
    let paddingTop = 18;
    let paddingBottom = 30;
    let series: WeeklyWeightPoint[] = this.weeklyWeightSeries();
    let minValue: number = series[0].value;
    let maxValue: number = series[0].value;

    for (let index = 1; index < series.length; index++) {
      minValue = Math.min(minValue, series[index].value);
      maxValue = Math.max(maxValue, series[index].value);
    }

    let range: number = Math.max(0.4, Number((maxValue - minValue).toFixed(2)) + 0.2);
    let topValue: number = maxValue + 0.1;
    let bottomValue: number = minValue - 0.1;
    let usableWidth: number = chartWidth - paddingLeft - paddingRight;
    let usableHeight: number = chartHeight - paddingTop - paddingBottom;
    let stepX: number = series.length > 1 ? usableWidth / (series.length - 1) : usableWidth;

    context.clearRect(0, 0, chartWidth, chartHeight);
    context.lineCap = 'round';
    context.lineJoin = 'round';

    for (let gridIndex = 0; gridIndex < 4; gridIndex++) {
      let y: number = paddingTop + (usableHeight / 3) * gridIndex;
      context.beginPath();
      context.lineWidth = 1;
      context.strokeStyle = '#EEF2F7';
      context.moveTo(paddingLeft, y);
      context.lineTo(chartWidth - paddingRight, y);
      context.stroke();
    }

    for (let pointIndex = 0; pointIndex < series.length; pointIndex++) {
      let x: number = paddingLeft + stepX * pointIndex;
      let ratio: number = (topValue - series[pointIndex].value) / range;
      let y: number = paddingTop + usableHeight * ratio;
      if (pointIndex === 0) {
        context.beginPath();
        context.moveTo(x, y);
      } else {
        context.lineTo(x, y);
      }
    }
    context.lineWidth = 3;
    context.strokeStyle = '#36C79A';
    context.stroke();

    for (let pointIndex = 0; pointIndex < series.length; pointIndex++) {
      let x: number = paddingLeft + stepX * pointIndex;
      let ratio: number = (topValue - series[pointIndex].value) / range;
      let y: number = paddingTop + usableHeight * ratio;

      context.beginPath();
      context.fillStyle = '#FFFFFF';
      context.arc(x, y, 5, 0, Math.PI * 2, false);
      context.fill();

      context.beginPath();
      context.lineWidth = 2;
      context.strokeStyle = '#36C79A';
      context.arc(x, y, 5, 0, Math.PI * 2, false);
      context.stroke();

      if (pointIndex === series.length - 1) {
        context.beginPath();
        context.fillStyle = 'rgba(54, 199, 154, 0.18)';
        context.arc(x, y, 9, 0, Math.PI * 2, false);
        context.fill();
      }
    }
  }

  weeklyGoalValueText(): string {
    return getWeeklyGoalValueText(this.profileSignature);
  }

  weightTrendSummary(): string {
    return getWeightTrendSummary(this.weekLoss);
  }

  weeklyProgressSummary(): string {
    return getWeeklyProgressSummary(this.streakDays, this.steps, this.water, this.currentDayExerciseRecords().length);
  }

  weeklySuggestionSummary(): string {
    return getWeeklySuggestionSummary(this.exerciseCaloriesBurned, this.calories);
  }

  goalPlanPreview(): string {
    return getGoalPlanPreview(this.weight, this.onboardingTargetWeight, this.profileGoalDraft,
      this.profileWeeklyTargetDraft, this.profileReminderTimeDraft);
  }

  goalDisplayText(): string {
    return getGoalDisplayText(this.weight, this.onboardingTargetWeight, this.profileGoalText);
  }

  profileMenuSubtitle(item: ProfileMenuItem): string {
    return getProfileMenuSubtitle(item, this.goalDisplayText(), this.profileEmail);
  }

  authErrorMessage(error: Object | string): string {
    if (error instanceof Error) {
      if (error.message.includes('Failed to fetch') || error.message.includes('Network')) {
        return '\u65e0\u6cd5\u8fde\u63a5\u5230\u540e\u7aef\u670d\u52a1\uff0c\u8bf7\u5148\u542f\u52a8 backend \u5e76\u68c0\u67e5 BACKEND_API_BASE_URL';
      }
      return error.message;
    }
    if (typeof error === 'string') {
      return error;
    }
    return '\u8bf7\u6c42\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5';
  }

  profileInitial(): string {
    return getProfileInitial(this.profileName);
  }

  handleProfileMenu(item: ProfileMenuItem): void {
    if (item.id === 1) {
      this.openProfilePanel('weekly');
      return;
    }
    if (item.id === 2) {
      this.openProfilePanel('goal');
      return;
    }
    if (item.id === 3) {
      this.openProfilePanel('security');
      return;
    }
    this.openProfilePanel('feedback');
  }

  handleProfileQuickTag(title: string): void {
    let action: ProfileQuickTagAction = resolveProfileQuickTagAction(title);
    if (action === 'goal') {
      this.openProfilePanel('goal');
      return;
    }
    if (action === 'steps') {
      this.currentTab = 0;
      this.tabsController.changeIndex(0);
      this.refreshDeviceSteps();
      return;
    }
    if (action === 'meal') {
      this.currentTab = 0;
      this.tabsController.changeIndex(0);
      this.openMealSheet('breakfast');
      return;
    }
    if (action === 'exercise') {
      this.currentTab = 0;
      this.tabsController.changeIndex(0);
      this.openExerciseSheet();
    }
  }

  handleMealAction(type: MealType | 'exercise'): void {
    if (type === 'exercise') {
      this.openExerciseSheet();
      return;
    }
    this.openMealSheet(type);
  }

  openExerciseSheet(): void {
    this.ensureDailyHealthStateCurrent();
    this.activeExerciseCategory = '\u70ed\u95e8';
    this.exerciseSearchKeyword = '';
    this.selectedExerciseId = -1;
    this.exerciseDurationDraft = '';
    this.isExerciseHistoryOpen = false;
    this.exerciseSheetTime = this.currentClock();
    this.isExerciseSheetOpen = true;
  }

  closeExerciseSheet(): void {
    this.selectedExerciseId = -1;
    this.exerciseDurationDraft = '';
    this.isExerciseHistoryOpen = false;
    this.isExerciseSheetOpen = false;
  }

  openExerciseHistory(): void {
    this.isExerciseHistoryOpen = true;
  }

  closeExerciseHistory(): void {
    this.isExerciseHistoryOpen = false;
  }

  currentExerciseOptions(): ExercisePresetItem[] {
    return exerciseOptionsForCategory(this.exercisePresets, this.activeExerciseCategory, this.exerciseSearchKeyword);
  }

  currentDayExerciseRecords(): ExerciseRecordItem[] {
    return exerciseRecordsForDay(this.exerciseRecords, this.currentDayKey());
  }

  selectedExerciseSummary(): string {
    for (let index = 0; index < this.exercisePresets.length; index++) {
      let item: ExercisePresetItem = this.exercisePresets[index];
      if (item.id === this.selectedExerciseId) {
        return `${item.name}  ${this.selectedExerciseDurationValue(item.duration)}\u5206\u949f  \u9884\u8ba1\u6d88\u8017 ${this.selectedExerciseCaloriesValue()} \u5343\u5361`;
      }
    }
    return '';
  }

  selectedExerciseDurationValue(defaultDuration: number = 0): number {
    return exerciseDurationValue(this.exerciseDurationDraft, defaultDuration);
  }

  selectedExerciseCaloriesValue(): number {
    return selectedExerciseCalories(this.exercisePresets, this.selectedExerciseId, this.exerciseDurationDraft);
  }

  saveExerciseSelection(): void {
    this.ensureDailyHealthStateCurrent();
    if (this.selectedExerciseId < 0) {
      this.closeExerciseSheet();
      return;
    }

    for (let index = 0; index < this.exercisePresets.length; index++) {
      let item: ExercisePresetItem = this.exercisePresets[index];
      if (item.id === this.selectedExerciseId) {
        let duration: number = this.selectedExerciseDurationValue(item.duration);
        let calories: number = exerciseCaloriesForDuration(item, duration);
        let nextRecord: ExerciseRecordItem = {
          id: Date.now(),
          name: item.name,
          calories: calories,
          duration: duration,
          category: item.category,
          time: this.currentClock(),
          dayKey: this.currentDayKey()
        };
        this.exerciseRecords = [nextRecord, ...this.exerciseRecords];
        this.syncExerciseCaloriesBurned();
        this.awardPoints(8);
        this.closeExerciseSheet();
        this.queuePersistAppState();
        return;
      }
    }

    this.closeExerciseSheet();
  }

  removeExerciseRecord(recordId: number): void {
    let nextRecords: ExerciseRecordItem[] = [];
    for (let index = 0; index < this.exerciseRecords.length; index++) {
      let item: ExerciseRecordItem = this.exerciseRecords[index];
      if (item.id !== recordId) {
        nextRecords.push(item);
      }
    }
    this.exerciseRecords = nextRecords;
    this.syncExerciseCaloriesBurned();
    this.queuePersistAppState();
  }

  syncExerciseCaloriesBurned(): void {
    let total: number = 0;
    let todayKey: string = this.currentDayKey();
    for (let index = 0; index < this.exerciseRecords.length; index++) {
      if (this.exerciseRecords[index].dayKey === todayKey) {
        total += this.exerciseRecords[index].calories;
      }
    }
    this.exerciseCaloriesBurned = total;
  }

  exerciseGoalDaysThisWeek(): number {
    return getExerciseGoalDaysThisWeek(this.exerciseWeekCalories());
  }

  exerciseDailyAverage(): number {
    return getExerciseDailyAverage(this.exerciseWeekCalories());
  }

  exerciseBarHeights(): number[] {
    return getExerciseBarHeights(this.exerciseWeekCalories());
  }

  exerciseWeekLabels(): string[] {
    return getExerciseWeekLabels();
  }

  exerciseWeekCalories(): number[] {
    return getExerciseWeekCalories(this.exerciseRecords, this.currentWeekDayKeys());
  }

  exerciseAdjustedCalories(): number {
    return getExerciseAdjustedCalories(this.exerciseCaloriesBurned);
  }

  openMealSheet(type: MealType): void {
    this.ensureDailyHealthStateCurrent();
    this.activeMealType = type;
    this.mealSheetTime = this.currentClock();
    this.mealSearchKeyword = '';
    this.mealSearchError = '';
    this.mealSearchResults = [];
    this.manualFoodNameDraft = '';
    this.manualFoodCaloriesDraft = '';
    this.manualFoodError = '';
    this.closeFavoriteEditor();
    this.isMealSheetOpen = true;
  }

  openMealSheetByLabel(label: string): void {
    if (label === '\u65e9\u9910') {
      this.openMealSheet('breakfast');
      return;
    }
    if (label === '\u5348\u9910') {
      this.openMealSheet('lunch');
      return;
    }
    if (label === '\u665a\u9910') {
      this.openMealSheet('dinner');
      return;
    }
  }

  closeMealSheet(): void {
    this.mealRecords = [...this.mealRecords];
    this.syncCalories(this.mealRecords);
    this.isMealSheetOpen = false;
    this.queuePersistAppState();
  }


  mealCalories(type: MealType): number {
    return mealCaloriesForType(this.mealRecords, this.currentDayKey(), type);
  }

  currentMealCaloriesValue(): number {
    return getCurrentMealCaloriesValue(this.activeMealType, {
      total: this.calories,
      breakfast: this.breakfastCalories,
      lunch: this.lunchCalories,
      dinner: this.dinnerCalories,
      snack: this.snackCalories
    });
  }

  totalCaloriesIntake(): number {
    return mealCalorieTotals(this.mealRecords, this.currentDayKey(), this.scannedCaloriesTotal).total;
  }

  currentMealRecords(): MealRecordItem[] {
    return mealRecordsForType(this.mealRecords, this.currentDayKey(), this.activeMealType);
  }

  currentMealPresetRows(): MealPresetItem[][] {
    return buildMealPresetRows(this.mealPresets, this.activeMealType);
  }

  favoriteFoodRows(): FavoriteFoodItem[][] {
    return buildFavoriteFoodRows(this.foodFavorites);
  }

  favoriteFoodRowKey(row: FavoriteFoodItem[]): string {
    return buildFavoriteFoodRowKey(row);
  }

  addFavoriteFood(name: string, calories: number, source: string): void {
    let safeName: string = name.trim();
    let safeCalories: number = Math.max(1, Math.round(calories));
    if (safeName.length === 0 || safeCalories <= 0) {
      return;
    }

    let nextFavorites: FavoriteFoodItem[] = [];
    let didUpdate: boolean = false;
    for (let index = 0; index < this.foodFavorites.length; index++) {
      let item: FavoriteFoodItem = this.foodFavorites[index];
      if (item.name.toLowerCase() === safeName.toLowerCase()) {
        nextFavorites.push({
          id: item.id,
          name: safeName,
          calories: safeCalories,
          source: source,
          lastUsedAt: this.currentClock()
        });
        didUpdate = true;
      } else {
        nextFavorites.push(item);
      }
    }
    if (!didUpdate) {
      nextFavorites.unshift({
        id: Date.now(),
        name: safeName,
        calories: safeCalories,
        source: source,
        lastUsedAt: this.currentClock()
      });
    }
    this.foodFavorites = nextFavorites.slice(0, 8);
    this.mealSearchError = `\u5df2\u6536\u85cf ${safeName}`;
    this.queuePersistAppState();
  }

  addFavoriteFoodRecord(item: FavoriteFoodItem): void {
    let nextRecord: MealRecordItem = {
      id: Date.now(),
      mealType: this.activeMealType,
      name: item.name,
      calories: item.calories,
      time: this.currentClock(),
      dayKey: this.currentDayKey()
    };
    this.addFavoriteFood(item.name, item.calories, item.source);
    this.appendMealRecord(nextRecord);
  }

  addManualFoodRecord(shouldFavorite: boolean): void {
    let safeName: string = this.manualFoodNameDraft.trim();
    let calories: number = Number(this.manualFoodCaloriesDraft.trim());
    if (safeName.length === 0) {
      this.manualFoodError = '\u8bf7\u5148\u8f93\u5165\u98df\u7269\u540d';
      return;
    }
    if (Number.isNaN(calories) || calories <= 0 || calories > 3000) {
      this.manualFoodError = '\u70ed\u91cf\u8bf7\u8f93\u5165 1~3000 kcal';
      return;
    }

    let roundedCalories: number = Math.round(calories);
    let nextRecord: MealRecordItem = {
      id: Date.now(),
      mealType: this.activeMealType,
      name: safeName,
      calories: roundedCalories,
      time: this.currentClock(),
      dayKey: this.currentDayKey()
    };
    this.appendMealRecord(nextRecord);
    if (shouldFavorite) {
      this.addFavoriteFood(safeName, roundedCalories, '\u624b\u52a8');
    }
    this.manualFoodNameDraft = '';
    this.manualFoodCaloriesDraft = '';
    this.manualFoodError = shouldFavorite ? '\u5df2\u52a0\u5165\u672c\u9910\u5e76\u6536\u85cf' : '\u5df2\u52a0\u5165\u672c\u9910';
  }

  openFavoriteEditor(item: FavoriteFoodItem): void {
    this.editingFavoriteId = item.id;
    this.favoriteEditNameDraft = item.name;
    this.favoriteEditCaloriesDraft = item.calories.toString();
    this.favoriteEditMessage = '';
  }

  closeFavoriteEditor(): void {
    this.editingFavoriteId = -1;
    this.favoriteEditNameDraft = '';
    this.favoriteEditCaloriesDraft = '';
    this.favoriteEditMessage = '';
  }

  saveFavoriteEdit(): void {
    if (this.editingFavoriteId <= 0) {
      this.favoriteEditMessage = '\u8bf7\u5148\u9009\u62e9\u8981\u7f16\u8f91\u7684\u6536\u85cf';
      return;
    }
    let safeName: string = this.favoriteEditNameDraft.trim();
    let calories: number = Number(this.favoriteEditCaloriesDraft.trim());
    if (safeName.length === 0) {
      this.favoriteEditMessage = '\u8bf7\u8f93\u5165\u98df\u7269\u540d';
      return;
    }
    if (Number.isNaN(calories) || calories <= 0 || calories > 3000) {
      this.favoriteEditMessage = '\u70ed\u91cf\u8bf7\u8f93\u5165 1~3000 kcal';
      return;
    }

    this.foodFavorites = updateFavoriteFood(this.foodFavorites, this.editingFavoriteId, safeName,
      Math.round(calories), this.currentClock());
    this.editingFavoriteId = -1;
    this.favoriteEditNameDraft = '';
    this.favoriteEditCaloriesDraft = '';
    this.favoriteEditMessage = `\u5df2\u66f4\u65b0 ${safeName}`;
    this.queuePersistAppState();
  }

  removeFavoriteFood(favoriteId: number): void {
    this.foodFavorites = deleteFavoriteFood(this.foodFavorites, favoriteId);
    if (this.editingFavoriteId === favoriteId) {
      this.editingFavoriteId = -1;
      this.favoriteEditNameDraft = '';
      this.favoriteEditCaloriesDraft = '';
    }
    this.favoriteEditMessage = '\u5df2\u5220\u9664\u6536\u85cf';
    this.queuePersistAppState();
  }

  mealPresetRowKey(row: MealPresetItem[]): string {
    return buildMealPresetRowKey(row);
  }

  searchMealFoods(): void {
    void this.performMealFoodSearch();
  }

  async performMealFoodSearch(): Promise<void> {
    let keyword: string = this.mealSearchKeyword.trim();
    let inputMessage: string = mealSearchInputMessage(keyword, this.isMealSearching);
    if (inputMessage.length > 0) {
      this.mealSearchError = inputMessage;
      return;
    }

    this.isMealSearching = true;
    this.mealSearchError = '';

    try {
      let results: BooheeFoodItem[] = await booheeFoodService.searchFoods(keyword);
      this.mealSearchResults = results;
      if (results.length === 0) {
        this.mealSearchError = '\u6ca1\u6709\u627e\u5230\u5339\u914d\u7684\u98df\u7269';
      }
    } catch (error) {
      this.mealSearchResults = [];
      this.mealSearchError = this.errorMessage(error);
    } finally {
      this.isMealSearching = false;
    }
  }

  addMealRecord(item: MealPresetItem): void {
    let nextRecord: MealRecordItem = {
      id: Date.now(),
      mealType: item.mealType,
      name: item.name,
      calories: item.calories,
      time: this.currentClock(),
      dayKey: this.currentDayKey()
    };
    this.appendMealRecord(nextRecord);
  }

  addSearchFoodRecord(item: BooheeFoodItem): void {
    let nextRecord: MealRecordItem = {
      id: Date.now(),
      mealType: this.activeMealType,
      name: item.name,
      calories: item.calories,
      time: this.currentClock(),
      dayKey: this.currentDayKey()
    };
    this.appendMealRecord(nextRecord);
  }

  adjustScannedCalories(delta: number): void {
    if (this.lastScannedCalories <= 0) {
      return;
    }
    this.lastScannedCalories = Math.max(1, Math.min(2000, this.lastScannedCalories + delta));
    this.lastScannedSummary = `\u5df2\u624b\u52a8\u6821\u6b63\u4e3a ${this.lastScannedCalories} \u5343\u5361`;
    this.lastScannedAssignedMeal = '';
    this.queuePersistAppState();
  }

  assignScannedFoodToMeal(type: MealType): void {
    this.ensureDailyHealthStateCurrent();
    if (this.lastScannedFood.length === 0 || this.lastScannedCalories <= 0) {
      return;
    }

    let nextRecord: MealRecordItem = {
      id: Date.now(),
      mealType: type,
      name: this.lastScannedFood,
      calories: this.lastScannedCalories,
      time: this.currentClock(),
      dayKey: this.currentDayKey()
    };
    this.appendMealRecord(nextRecord);
    this.lastScannedAssignedMeal = `\u5df2\u6dfb\u52a0\u5230${mealLabel(type)}`;
    this.queuePersistAppState();
  }

  appendMealRecord(record: MealRecordItem): void {
    this.ensureDailyHealthStateCurrent();
    let nextRecords: MealRecordItem[] = [record, ...this.mealRecords];
    this.mealRecords = nextRecords;
    this.applyMealCaloriesDelta(record.mealType, record.calories);
    this.mealSheetTime = record.time;
    this.awardPoints(3);
    this.queuePersistAppState();
  }

  removeMealRecord(recordId: number): void {
    let hasRemovedRecord: boolean = false;
    let removedMealType: MealType = 'breakfast';
    let removedCalories: number = 0;
    let nextRecords: MealRecordItem[] = [];
    for (let index = 0; index < this.mealRecords.length; index++) {
      let item: MealRecordItem = this.mealRecords[index];
      if (item.id !== recordId) {
        nextRecords.push(item);
      } else {
        hasRemovedRecord = true;
        removedMealType = item.mealType;
        removedCalories = item.calories;
      }
    }
    this.mealRecords = nextRecords;
    if (hasRemovedRecord) {
      this.applyMealCaloriesDelta(removedMealType, -removedCalories);
    } else {
      this.syncCalories(nextRecords);
    }
    this.queuePersistAppState();
  }

  syncCalories(records: MealRecordItem[] = this.mealRecords): void {
    let totals: MealCalorieTotals = mealCalorieTotals(records, this.currentDayKey(), this.scannedCaloriesTotal);
    this.breakfastCalories = totals.breakfast;
    this.lunchCalories = totals.lunch;
    this.dinnerCalories = totals.dinner;
    this.snackCalories = totals.snack;
    this.calories = totals.total;
  }

  applyMealCaloriesDelta(type: MealType, delta: number): void {
    let totals: MealCalorieTotals = calculateMealCaloriesDelta({
      total: this.calories,
      breakfast: this.breakfastCalories,
      lunch: this.lunchCalories,
      dinner: this.dinnerCalories,
      snack: this.snackCalories
    }, type, delta, this.scannedCaloriesTotal);
    this.breakfastCalories = totals.breakfast;
    this.lunchCalories = totals.lunch;
    this.dinnerCalories = totals.dinner;
    this.snackCalories = totals.snack;
    this.calories = totals.total;
  }

  currentClock(): string {
    return currentClockText();
  }

  currentDayKey(): string {
    return currentDateKey();
  }

  dateFromDayKey(dayKey: string): Date {
    return dateFromKey(dayKey);
  }

  dayKeyFromOffset(offsetDays: number): string {
    return dayKeyWithOffset(offsetDays);
  }

  currentWeekDayKeys(): string[] {
    return weekDayKeys();
  }

  stepDisplayText(): string {
    if (!this.isStepSensorReady && this.steps <= 0) {
      return '--';
    }
    return `${this.steps} \u6b65`;
  }

  stepButtonText(): string {
    if (this.isStepSensorReady) {
      return '\u5237\u65b0\u6b65\u6570';
    }
    return '\u5f00\u542f\u6b65\u6570';
  }

  getHostContext(): common.Context | undefined {
    let context: common.Context | undefined = this.getUIContext().getHostContext();
    return context;
  }

  async ensureMotionPermission(context: common.Context): Promise<boolean> {
    if (this.isStepPermissionGranted) {
      return true;
    }

    try {
      let atManager = abilityAccessCtrl.createAtManager();
      let permissions: Permissions[] = [this.activityMotionPermission];
      let grantResult = await atManager.requestPermissionsFromUser(context, permissions);
      let granted: boolean = grantResult.authResults.length > 0 && grantResult.authResults[0] === 0;
      this.isStepPermissionGranted = granted;
      return granted;
    } catch (error) {
      this.isStepPermissionGranted = false;
      return false;
    }
  }

  async startStepSync(): Promise<void> {
    if (this.isStepSensorListening) {
      return;
    }

    let context: common.Context | undefined = this.getHostContext();
    if (context === undefined) {
      this.stepSyncMessage = '\u65e0\u6cd5\u83b7\u53d6\u4e0a\u4e0b\u6587';
      return;
    }

    this.stepSyncMessage = '\u6b63\u5728\u8bf7\u6c42\u8fd0\u52a8\u6743\u9650';

    try {
      let granted: boolean = await this.ensureMotionPermission(context);
      if (!granted) {
        this.isStepSensorReady = false;
        this.stepSyncMessage = '\u672a\u5f00\u542f\u8fd0\u52a8\u6743\u9650';
        return;
      }

      let options: sensor.Options = {
        interval: 'normal'
      };
      sensor.on(sensor.SensorId.PEDOMETER, (data: sensor.PedometerResponse): void => {
        this.applyPedometerData(data);
      }, options);
      this.isStepSensorListening = true;
      this.isStepSensorReady = true;
      this.stepSyncMessage = '\u5df2\u8fde\u63a5\u624b\u673a\u4f20\u611f\u5668';
      this.refreshDeviceSteps();
    } catch (error) {
      this.isStepSensorReady = false;
      this.stepSyncMessage = '\u8bbe\u5907\u4e0d\u652f\u6301\u6b65\u6570\u4f20\u611f\u5668';
    }
  }

  stopStepSync(): void {
    if (!this.isStepSensorListening) {
      return;
    }

    try {
      sensor.off(sensor.SensorId.PEDOMETER);
    } catch (error) {
    }

    this.isStepSensorListening = false;
  }

  refreshDeviceSteps(): void {
    this.ensureDailyHealthStateCurrent();
    void this.requestDeviceStepsOnce();
  }

  async requestDeviceStepsOnce(): Promise<void> {
    if (!this.isStepSensorListening) {
      await this.startStepSync();
      return;
    }

    this.stepSyncMessage = '\u6b63\u5728\u540c\u6b65\u624b\u673a\u6b65\u6570';

    try {
      sensor.once(sensor.SensorId.PEDOMETER, (data: sensor.PedometerResponse): void => {
        this.applyPedometerData(data);
      });
    } catch (error) {
      this.isStepSensorReady = false;
      this.stepSyncMessage = '\u540c\u6b65\u5931\u8d25\uff0c\u8bf7\u5b9e\u673a\u91cd\u8bd5';
    }
  }

  applyPedometerData(data: sensor.PedometerResponse): void {
    this.steps = data.steps;
    this.isStepSensorReady = true;
    this.stepSyncMessage = '\u5df2\u540c\u6b65\u624b\u673a\u6b65\u6570';
    this.queuePersistAppState();
  }

  async pickFoodPhoto(): Promise<string> {
    let picker = new photoAccessHelper.PhotoViewPicker();
    let options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = 1;
    options.isPhotoTakingSupported = true;
    options.isSearchSupported = false;
    options.isEditSupported = false;
    options.isOriginalSupported = false;

    try {
      let result = await picker.select(options);
      if (result.photoUris.length === 0) {
        return '';
      }
      return result.photoUris[0];
    } catch (error) {
      return '';
    }
  }

  async convertImageUriToBase64(uri: string): Promise<string> {
    let context: common.Context | undefined = this.getUIContext().getHostContext();
    if (context === undefined) {
      throw new Error('\u65e0\u6cd5\u83b7\u53d6\u5e94\u7528\u4e0a\u4e0b\u6587');
    }

    let helper = photoAccessHelper.getPhotoAccessHelper(context);
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(photoAccessHelper.PhotoKeys.URI, uri);

    let fetchOptions: photoAccessHelper.FetchOptions = {
      fetchColumns: [photoAccessHelper.PhotoKeys.URI],
      predicates: predicates
    };
    let fetchResult: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset> | undefined = undefined;
    try {
      fetchResult = await helper.getAssets(fetchOptions);
    } catch (error) {
      throw new Error(this.errorMessage(error));
    }

    try {
      try {
        if (fetchResult === undefined) {
          throw new Error('\u65e0\u6cd5\u83b7\u53d6\u56fe\u7247\u8d44\u4ea7');
        }
        if (fetchResult.getCount() === 0) {
          throw new Error('\u672a\u627e\u5230\u9009\u4e2d\u7684\u56fe\u7247\u8d44\u4ea7');
        }

        let asset = await fetchResult.getFirstObject();
        let imageData: ArrayBuffer = await this.requestPhotoAssetData(context, asset);
        return buffer.from(new Uint8Array(imageData)).toString('base64');
      } catch (error) {
        throw new Error(this.errorMessage(error));
      }
    } finally {
      try {
        fetchResult?.close();
      } catch (error) {
      }
    }
  }

  detectImageMimeType(uri: string): string {
    let lowerCaseUri: string = uri.toLowerCase();
    if (lowerCaseUri.includes('.png')) {
      return 'image/png';
    }
    if (lowerCaseUri.includes('.webp')) {
      return 'image/webp';
    }
    if (lowerCaseUri.includes('.heic')) {
      return 'image/heic';
    }
    if (lowerCaseUri.includes('.heif')) {
      return 'image/heif';
    }
    return 'image/jpeg';
  }

  requestPhotoAssetData(context: common.Context, asset: photoAccessHelper.PhotoAsset): Promise<ArrayBuffer> {
    let requestOptions: photoAccessHelper.RequestOptions = {
      deliveryMode: photoAccessHelper.DeliveryMode.HIGH_QUALITY_MODE
    };

    return new Promise<ArrayBuffer>((resolve: (value: ArrayBuffer) => void, reject: (reason?: Object | string) => void) => {
      let settled: boolean = false;
      let dataHandler: photoAccessHelper.MediaAssetDataHandler<ArrayBuffer> = {
        onDataPrepared: (data: ArrayBuffer): void => {
          if (settled) {
            return;
          }
          settled = true;
          resolve(data);
        }
      };

      photoAccessHelper.MediaAssetManager.requestImageData(context, asset, requestOptions, dataHandler)
        .catch((error: Object | string) => {
          if (settled) {
            return;
          }
          settled = true;
          reject(error);
        });
    });
  }

  errorMessage(error: Object | string): string {
    if (error instanceof Error) {
      return error.message;
    }
    if (typeof error === 'string') {
      return error;
    }
    return '\u65e0\u6cd5\u5b8c\u6210\u8bc6\u522b\uff0c\u8bf7\u7a0d\u540e\u518d\u8bd5\u3002';
  }
}
