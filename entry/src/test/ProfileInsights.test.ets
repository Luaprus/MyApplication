import { describe, it, expect } from '@ohos/hypium';
import { goalPlanPreview } from '../main/ets/models/ProfileInsights';

export default function profileInsightsTest() {
  describe('profileInsightsTest', () => {
    it('goalPlanPreview should prefer the edited stage goal over stale onboarding target weight', 0, () => {
      let preview: string = goalPlanPreview(82.3, '46.0', '\u51cf\u8102 3.2kg', '0.3', '21:00');

      expect(preview).assertContain('\u51cf\u8102 3.2kg');
      expect(preview).assertContain('\u672c\u5468\u671f\u5f85\u8fdb\u5c55 0.3kg');
      expect(preview).assertContain('21:00');
      expect(preview.includes('46.0kg')).assertFalse();
      expect(preview.includes('36.3kg')).assertFalse();
    });
  });
}
