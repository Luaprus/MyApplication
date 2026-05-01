import { describe, it, expect } from '@ohos/hypium';
import { buildHealthAssistantSystemPrompt, buildWeeklyReportPrompt, HealthPromptContext } from '../main/ets/models/AiPromptBuilders';

export default function aiPromptBuildersTest() {
  describe('aiPromptBuildersTest', () => {
    it('buildHealthAssistantSystemPrompt should include current metrics and reminders', 0, () => {
      let prompt: string = buildHealthAssistantSystemPrompt(sampleContext());

      expect(prompt).assertContain('61.20 kg');
      expect(prompt).assertContain('\u996e\u6c34\u8fdb\u5ea6\u504f\u4f4e');
      expect(prompt).assertContain('Current achievement points today: 22');
    });

    it('buildWeeklyReportPrompt should include richer weekly sections', 0, () => {
      let prompt: string = buildWeeklyReportPrompt(sampleContext());

      expect(prompt).assertContain('\u505a\u5f97\u597d\u7684\u5730\u65b9');
      expect(prompt).assertContain('\u4e0b\u5468\u76ee\u6807');
      expect(prompt).assertContain('\u996e\u98df\u5efa\u8bae');
      expect(prompt).assertContain('\u8fd0\u52a8\u5efa\u8bae');
    });
  });
}

function sampleContext(): HealthPromptContext {
  return {
    weight: 61.2,
    calories: 1420,
    water: 900,
    steps: 6200,
    streakDays: 6,
    weekLoss: 0.4,
    exerciseCalories: 160,
    goalAdjustment: {
      calorieText: '\u4eca\u65e5\u8fd8\u53ef\u7075\u6d3b\u5b89\u6392',
      exerciseText: '\u8865\u4e00\u6b21 20 \u5206\u949f\u8f7b\u8fd0\u52a8',
      paceText: '\u8282\u594f\u6b63\u5e38'
    },
    reminders: [
      {
        title: '\u996e\u6c34\u8fdb\u5ea6\u504f\u4f4e',
        message: '\u8fd8\u9700\u8865\u6c34',
        tint: '#32C5F4',
        bgColor: '#E9F9FF'
      }
    ],
    achievementSummary: {
      points: 22,
      lines: ['\u8fde\u7eed\u6253\u5361 +12', '\u5b8c\u6210\u8fd0\u52a8 +10']
    }
  };
}
