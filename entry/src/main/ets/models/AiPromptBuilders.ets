import { AchievementSummary, GoalAdjustment, SmartReminder } from './FeatureInsights';

export interface HealthPromptContext {
  weight: number;
  calories: number;
  water: number;
  steps: number;
  streakDays: number;
  weekLoss: number;
  exerciseCalories: number;
  goalAdjustment: GoalAdjustment;
  reminders: SmartReminder[];
  achievementSummary: AchievementSummary;
}

export function buildHealthAssistantSystemPrompt(context: HealthPromptContext): string {
  return [
    'You are a helpful health assistant for a HarmonyOS app.',
    'Answer in concise Chinese by default.',
    `Current user metrics: weight ${context.weight.toFixed(2)} kg, calories ${context.calories} kcal, water ${context.water} ml, steps ${context.steps}, streak ${context.streakDays} days, weekly weight change ${context.weekLoss.toFixed(2)} kg, exercise ${context.exerciseCalories} kcal, goal pace ${context.goalAdjustment.paceText}.`,
    `Current reminders: ${reminderSummary(context.reminders)}.`,
    `Current achievement points today: ${context.achievementSummary.points}.`,
    'Use meal, water, exercise, weight, reminders, achievements, and goal adjustment records when relevant.'
  ].join(' ');
}

export function buildWeeklyReportPrompt(context: HealthPromptContext): string {
  return [
    '\u8bf7\u751f\u6210\u4e00\u4efd\u672c\u5468 AI \u5065\u5eb7\u5468\u62a5\uff0c\u7528\u6e29\u548c\u4f46\u5177\u4f53\u7684\u4e2d\u6587\u8868\u8fbe\u3002',
    '\u8bf7\u5206\u4e3a\u201c\u505a\u5f97\u597d\u7684\u5730\u65b9\u201d\u201c\u9700\u8981\u6ce8\u610f\u7684\u98ce\u9669\u201d\u201c\u4e0b\u5468\u76ee\u6807\u201d\u4e09\u6bb5\uff0c\u6bcf\u6bb5 2-3 \u6761\u3002',
    `\u6570\u636e\uff1a\u4f53\u91cd ${context.weight.toFixed(2)}kg\uff0c\u672c\u5468\u53d8\u5316 ${context.weekLoss.toFixed(2)}kg\uff0c\u6b65\u6570 ${context.steps}\uff0c\u996e\u98df ${context.calories}kcal\uff0c\u996e\u6c34 ${context.water}ml\uff0c\u8fd0\u52a8\u6d88\u8017 ${context.exerciseCalories}kcal\uff0c\u8fde\u7eed\u6253\u5361 ${context.streakDays} \u5929\u3002`,
    `\u76ee\u6807\u8282\u594f\uff1a${context.goalAdjustment.paceText}\u3002`,
    `\u667a\u80fd\u63d0\u9192\uff1a${reminderSummary(context.reminders)}\u3002`,
    `\u4eca\u65e5\u79ef\u5206\uff1a${context.achievementSummary.points}\uff0c\u660e\u7ec6\uff1a${achievementLines(context.achievementSummary)}\u3002`,
    `\u996e\u98df\u5efa\u8bae\uff1a${context.goalAdjustment.calorieText}`,
    `\u8fd0\u52a8\u5efa\u8bae\uff1a${context.goalAdjustment.exerciseText}`
  ].join('\n');
}

function reminderSummary(reminders: SmartReminder[]): string {
  if (reminders.length === 0) {
    return '\u6682\u65e0\u98ce\u9669\u63d0\u9192';
  }
  let titles: string[] = [];
  for (let index = 0; index < reminders.length; index++) {
    titles.push(reminders[index].title);
  }
  return titles.join('\uff0c');
}

function achievementLines(summary: AchievementSummary): string {
  if (summary.lines.length === 0) {
    return '\u6682\u65e0\u989d\u5916\u52a0\u5206\u9879';
  }
  return summary.lines.join('\uff0c');
}
