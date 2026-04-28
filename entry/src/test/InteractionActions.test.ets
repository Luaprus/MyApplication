import { describe, it, expect } from '@ohos/hypium';
import { mealSearchInputMessage, resolveProfileQuickTagAction } from '../main/ets/models/InteractionActions';

export default function interactionActionsTest() {
  describe('interactionActionsTest', () => {
    it('resolveProfileQuickTagAction should map visible profile tags to actions', 0, () => {
      expect(resolveProfileQuickTagAction('\u76ee\u6807')).assertEqual('goal');
      expect(resolveProfileQuickTagAction('\u6b65\u6570')).assertEqual('steps');
      expect(resolveProfileQuickTagAction('\u4eca\u65e5\u996e\u98df')).assertEqual('meal');
      expect(resolveProfileQuickTagAction('\u8fd0\u52a8\u6d88\u8017')).assertEqual('exercise');
      expect(resolveProfileQuickTagAction('\u672a\u77e5')).assertEqual('none');
    });

    it('mealSearchInputMessage should explain why search did not run', 0, () => {
      expect(mealSearchInputMessage('', false)).assertEqual('\u8bf7\u8f93\u5165\u8981\u641c\u7d22\u7684\u98df\u7269\u540d\u79f0');
      expect(mealSearchInputMessage('   ', false)).assertEqual('\u8bf7\u8f93\u5165\u8981\u641c\u7d22\u7684\u98df\u7269\u540d\u79f0');
      expect(mealSearchInputMessage('\u82f9\u679c', true)).assertEqual('\u6b63\u5728\u641c\u7d22\u4e2d\uff0c\u7a0d\u7b49\u4e00\u4e0b');
      expect(mealSearchInputMessage('\u82f9\u679c', false)).assertEqual('');
    });
  });
}
