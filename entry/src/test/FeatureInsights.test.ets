import { describe, it, expect } from '@ohos/hypium';
import {
  AchievementSummary,
  buildSmartReminders,
  buildGoalAdjustment,
  buildAchievementSummary,
  buildHealthDataCsv,
  buildMonthCalendarDayKeys,
  buildTrendDaySummaries,
  calculateWeekLoss,
  deleteFavoriteFood,
  firstWeightForDay,
  GoalAdjustment,
  latestWeightForDay,
  SmartReminder,
  TrendDaySummary,
  upsertWeightRecordKeepingBaseline,
  updateFavoriteFood
} from '../main/ets/models/FeatureInsights';
import { ExerciseRecordItem, FavoriteFoodItem, MealRecordItem, WaterRecordItem, WeightRecordItem } from '../main/ets/models/AppState';

export default function featureInsightsTest() {
  describe('featureInsightsTest', () => {
    it('buildTrendDaySummaries should summarize records by day', 0, () => {
      let days: string[] = ['2026-04-21', '2026-04-22'];
      let meals: MealRecordItem[] = [
        { id: 1, mealType: 'breakfast', name: '\u9e21\u86cb', calories: 120, time: '08:00', dayKey: '2026-04-22' }
      ];
      let waters: WaterRecordItem[] = [
        { id: 2, amount: 350, drinkName: '\u6c34', time: '09:00', dayKey: '2026-04-22' }
      ];
      let exercises: ExerciseRecordItem[] = [
        { id: 3, name: '\u5feb\u8d70', calories: 80, duration: 20, category: '\u70ed\u95e8', time: '19:00', dayKey: '2026-04-22' }
      ];
      let weights: WeightRecordItem[] = [
        { id: 4, value: 61.5, time: '07:30', dayKey: '2026-04-22' }
      ];

      let summaries: TrendDaySummary[] = buildTrendDaySummaries(days, meals, waters, exercises, weights);

      expect(summaries.length).assertEqual(2);
      expect(summaries[1].calories).assertEqual(120);
      expect(summaries[1].water).assertEqual(350);
      expect(summaries[1].exerciseCalories).assertEqual(80);
      expect(summaries[1].weightText).assertEqual('61.5kg');
    });

    it('buildMonthCalendarDayKeys should generate monday-first month grid', 0, () => {
      let keys: string[] = buildMonthCalendarDayKeys('2026-04-15');

      expect(keys.length).assertEqual(35);
      expect(keys[0]).assertEqual('2026-03-30');
      expect(keys[2]).assertEqual('2026-04-01');
      expect(keys[34]).assertEqual('2026-05-03');
    });

    it('buildSmartReminders should call out missing core records', 0, () => {
      let reminders: SmartReminder[] = buildSmartReminders(500, 2000, 0, 4, true);

      expect(reminders.length).assertEqual(3);
      expect(reminders[0].title).assertEqual('\u996e\u6c34\u8fdb\u5ea6\u504f\u4f4e');
      expect(reminders[1].title).assertEqual('\u665a\u9910\u8fd8\u6ca1\u8bb0');
      expect(reminders[2].title).assertEqual('\u9700\u8981\u79f0\u4e00\u6b21\u4f53\u91cd');
    });

    it('buildGoalAdjustment should react to weekly progress', 0, () => {
      let slow: GoalAdjustment = buildGoalAdjustment(1200, 180, 0.1, 0.5);
      let fast: GoalAdjustment = buildGoalAdjustment(900, 480, 0.9, 0.4);

      expect(slow.calorieText).assertContain('\u53ef\u4ee5\u518d\u5c11\u5403');
      expect(fast.exerciseText).assertContain('\u6062\u590d');
    });

    it('buildAchievementSummary should award concrete points', 0, () => {
      let summary: AchievementSummary = buildAchievementSummary(8, 2300, 2200, 250, 3);

      expect(summary.points).assertEqual(47);
      expect(summary.lines.length).assertEqual(4);
    });

    it('buildHealthDataCsv should export all record categories', 0, () => {
      let csv: string = buildHealthDataCsv(
        [{ id: 1, mealType: 'breakfast', name: '\u9e21\u86cb', calories: 120, time: '08:00', dayKey: '2026-04-22' }],
        [{ id: 2, amount: 350, drinkName: '\u6c34', time: '09:00', dayKey: '2026-04-22' }],
        [{ id: 3, value: 61.5, time: '07:30', dayKey: '2026-04-22' }],
        [{ id: 4, name: '\u5feb\u8d70', calories: 80, duration: 20, category: '\u70ed\u95e8', time: '19:00', dayKey: '2026-04-22' }]
      );

      expect(csv).assertContain('type,day,time,name,value,unit');
      expect(csv).assertContain('meal,2026-04-22,08:00,\u9e21\u86cb,120,kcal');
      expect(csv).assertContain('water,2026-04-22,09:00,\u6c34,350,ml');
      expect(csv).assertContain('weight,2026-04-22,07:30,\u4f53\u91cd,61.5,kg');
      expect(csv).assertContain('exercise,2026-04-22,19:00,\u5feb\u8d70 20\u5206\u949f,80,kcal');
    });

    it('favorite helpers should edit and delete favorite food', 0, () => {
      let favorites: FavoriteFoodItem[] = [
        { id: 1, name: '\u9e21\u86cb', calories: 120, source: '\u624b\u52a8', lastUsedAt: '08:00' },
        { id: 2, name: '\u725b\u5976', calories: 160, source: '\u98df\u7269\u5e93', lastUsedAt: '09:00' }
      ];

      let edited: FavoriteFoodItem[] = updateFavoriteFood(favorites, 1, '\u6c34\u716e\u86cb', 78, '10:00');
      let deleted: FavoriteFoodItem[] = deleteFavoriteFood(edited, 2);

      expect(edited[0].name).assertEqual('\u6c34\u716e\u86cb');
      expect(edited[0].calories).assertEqual(78);
      expect(deleted.length).assertEqual(1);
      expect(deleted[0].id).assertEqual(1);
    });

    it('weight helpers should keep first daily weight as weekly baseline', 0, () => {
      let records: WeightRecordItem[] = [
        { id: 1, value: 61.9, time: '08:00', dayKey: '2026-04-22' }
      ];

      let updated: WeightRecordItem[] = upsertWeightRecordKeepingBaseline(records,
        { id: 2, value: 61.2, time: '20:00', dayKey: '2026-04-22' });

      expect(updated.length).assertEqual(2);
      expect(firstWeightForDay(updated, '2026-04-22')).assertEqual(61.9);
      expect(latestWeightForDay(updated, '2026-04-22')).assertEqual(61.2);
      expect(calculateWeekLoss(updated, 61.2, [
        '2026-04-20', '2026-04-21', '2026-04-22', '2026-04-23', '2026-04-24', '2026-04-25', '2026-04-26'
      ])).assertEqual(0.7);
    });
  });
}
