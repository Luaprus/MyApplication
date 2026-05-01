import { describe, it, expect } from '@ohos/hypium';
import { buildDailyCompletionSummary, DailyCompletionSummary } from '../main/ets/models/RecordInsights';

export default function recordInsightsTest() {
  describe('recordInsightsTest', () => {
    it('buildDailyCompletionSummary should score incomplete day', 0, () => {
      let summary: DailyCompletionSummary = buildDailyCompletionSummary(1, 500, 2000, 0, false);

      expect(summary.percent).assertEqual(0);
      expect(summary.completedCount).assertEqual(0);
      expect(summary.totalCount).assertEqual(4);
      expect(summary.actionText).assertEqual('\u5148\u8865\u5168\u4e09\u9910\u8bb0\u5f55');
    });

    it('buildDailyCompletionSummary should score completed day', 0, () => {
      let summary: DailyCompletionSummary = buildDailyCompletionSummary(3, 2100, 2000, 220, true);

      expect(summary.percent).assertEqual(100);
      expect(summary.completedCount).assertEqual(4);
      expect(summary.actionText).assertEqual('\u53bb\u770b AI \u5468\u62a5');
      expect(summary.items[1].valueText).assertEqual('100%');
    });
  });
}
