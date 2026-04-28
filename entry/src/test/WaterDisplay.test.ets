import { describe, it, expect } from '@ohos/hypium';
import { WaterRecordItem } from '../main/ets/models/AppState';
import { buildWaterCardDisplayState, buildWaterCardDisplayStateFromTotal, sumWaterAmounts } from '../main/ets/models/WaterDisplay';

export default function waterDisplayTest() {
  describe('waterDisplayTest', () => {
    it('buildWaterCardDisplayState should show empty state when no record exists', 0, () => {
      let state = buildWaterCardDisplayState([], 2200);

      expect(state.total).assertEqual(0);
      expect(state.valueText).assertEqual('0 ml');
      expect(state.buttonText).assertEqual('\u53bb\u8bb0\u5f55');
      expect(state.subtitleText).assertContain('\u7b2c\u4e00\u676f');
    });

    it('buildWaterCardDisplayState should summarize today records', 0, () => {
      let records: WaterRecordItem[] = [
        {
          id: 1,
          amount: 350,
          drinkName: '\u8336\u6c34',
          time: '09:30',
          dayKey: '2026-04-23'
        },
        {
          id: 2,
          amount: 200,
          drinkName: '\u6c34',
          time: '08:00',
          dayKey: '2026-04-23'
        }
      ];

      let total = sumWaterAmounts(records);
      let state = buildWaterCardDisplayState(records, 1500);

      expect(total).assertEqual(550);
      expect(state.total).assertEqual(550);
      expect(state.valueText).assertEqual('550 ml');
      expect(state.buttonText).assertEqual('\u518d\u8bb0\u4e00\u676f');
      expect(state.subtitleText).assertContain('\u8336\u6c34 350ml');
      expect(state.subtitleText).assertContain('950ml');
    });

    it('buildWaterCardDisplayStateFromTotal should keep total even when only latest record is available', 0, () => {
      let state = buildWaterCardDisplayStateFromTotal(550, 1500, {
        id: 3,
        amount: 350,
        drinkName: '\u8336\u6c34',
        time: '09:30',
        dayKey: '2026-04-23'
      });

      expect(state.total).assertEqual(550);
      expect(state.valueText).assertEqual('550 ml');
      expect(state.buttonText).assertEqual('\u518d\u8bb0\u4e00\u676f');
      expect(state.subtitleText).assertContain('\u8336\u6c34 350ml');
      expect(state.subtitleText).assertContain('950ml');
    });
  });
}
