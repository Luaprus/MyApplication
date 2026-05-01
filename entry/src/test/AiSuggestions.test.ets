import { describe, it, expect } from '@ohos/hypium';
import { buildAiSuggestions, WEEKLY_REPORT_LABEL } from '../main/ets/models/AiSuggestions';
import { SuggestionItem } from '../main/ets/models/PageModels';

export default function aiSuggestionsTest() {
  describe('aiSuggestionsTest', () => {
    it('buildAiSuggestions should prioritize missing daily records', 0, () => {
      let suggestions: SuggestionItem[] = buildAiSuggestions({
        water: 500,
        waterGoal: 2000,
        dinnerCalories: 0,
        exerciseCalories: 0,
        daysSinceWeight: 4,
        weekLoss: 0.1
      });

      expect(suggestions.length).assertEqual(3);
      expect(suggestions[0].label).assertEqual(WEEKLY_REPORT_LABEL);
      expect(suggestions[1].label).assertContain('\u996e\u6c34');
      expect(suggestions[2].label).assertContain('\u665a\u9910');
    });

    it('buildAiSuggestions should fall back to general prompts', 0, () => {
      let suggestions: SuggestionItem[] = buildAiSuggestions({
        water: 2200,
        waterGoal: 2000,
        dinnerCalories: 420,
        exerciseCalories: 220,
        daysSinceWeight: 0,
        weekLoss: 0.2
      });

      expect(suggestions.length).assertEqual(3);
      expect(suggestions[0].label).assertEqual(WEEKLY_REPORT_LABEL);
      expect(suggestions[1].label).assertContain('\u8fd8\u80fd\u5403');
      expect(suggestions[2].label).assertContain('\u660e\u5929\u8fd0\u52a8');
    });
  });
}
