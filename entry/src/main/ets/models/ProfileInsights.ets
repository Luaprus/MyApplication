import { ProfileMenuItem } from './PageModels';

export function profileHealthScore(steps: number, exerciseCaloriesBurned: number, water: number,
  streakDays: number): number {
  let score: number = 58;
  score += Math.min(16, Math.floor(steps / 800));
  score += Math.min(12, Math.floor(exerciseCaloriesBurned / 25));
  score += Math.min(8, Math.floor(water / 250));
  score += Math.min(6, streakDays);
  return Math.max(60, Math.min(99, score));
}

export function profileBenefitCount(notificationEnabled: boolean, aiDigestEnabled: boolean,
  stepSyncEnabled: boolean, waterReminderEnabled: boolean): number {
  let count: number = 4;
  if (notificationEnabled) {
    count += 1;
  }
  if (aiDigestEnabled) {
    count += 1;
  }
  if (stepSyncEnabled) {
    count += 1;
  }
  if (waterReminderEnabled) {
    count += 1;
  }
  return count;
}

export function weeklyGoalValueText(profileSignature: string): string {
  let matchResult: RegExpMatchArray | null = profileSignature.match(/\d+(\.\d+)?/);
  if (matchResult && matchResult.length > 0) {
    return matchResult[0];
  }
  return '0.3';
}

export function weightTrendSummary(weekLoss: number): string {
  if (weekLoss > 0) {
    return `\u672c\u5468\u76f8\u6bd4\u4e0a\u5468\u5df2\u4e0b\u964d ${weekLoss.toFixed(2)}kg\uff0c\u8282\u594f\u6bd4\u8f83\u7a33\u5b9a\u3002`;
  }
  if (weekLoss < 0) {
    return `\u672c\u5468\u4f53\u91cd\u4e0a\u6d6e ${Math.abs(weekLoss).toFixed(2)}kg\uff0c\u53ef\u4ee5\u56de\u770b\u4e00\u4e0b\u665a\u9910\u548c\u52a0\u9910\u3002`;
  }
  return '\u672c\u5468\u4f53\u91cd\u57fa\u672c\u7ef4\u6301\u7a33\u5b9a\uff0c\u9002\u5408\u7ee7\u7eed\u4fdd\u6301\u5f53\u524d\u8282\u594f\u3002';
}

export function weeklyProgressSummary(streakDays: number, steps: number, water: number,
  exerciseRecordCount: number): string {
  return `\u8fde\u7eed\u6253\u5361 ${streakDays} \u5929\uff0c\u5f53\u524d\u6b65\u6570 ${steps}\uff0c\u996e\u6c34 ${water}ml\uff0c\u8fd0\u52a8\u8bb0\u5f55 ${exerciseRecordCount} \u6761\u3002`;
}

export function weeklySuggestionSummary(exerciseCaloriesBurned: number, calories: number): string {
  if (exerciseCaloriesBurned < 180) {
    return '\u8fd9\u5468\u53ef\u4ee5\u518d\u589e\u52a0 1 \u6b21 20~30 \u5206\u949f\u7684\u8f7b\u4e2d\u5ea6\u8bad\u7ec3\uff0c\u8ba9\u6d88\u8017\u66f4\u8fde\u8d2f\u3002';
  }
  if (calories > 1800) {
    return '\u4f60\u7684\u996e\u98df\u6444\u5165\u7565\u9ad8\uff0c\u665a\u9910\u53ef\u4ee5\u518d\u7b80\u5316\u4e00\u70b9\uff0c\u52a0\u9910\u4f18\u5148\u9009\u6c34\u679c\u6216\u9178\u5976\u3002';
  }
  return '\u73b0\u5728\u7684\u8282\u594f\u5f88\u597d\uff0c\u4f18\u5148\u7a33\u4f4f\u6253\u5361\u9891\u7387\uff0c\u8ba9\u4f53\u91cd\u53d8\u5316\u66f4\u5e73\u6ed1\u3002';
}

export function goalPlanPreview(weight: number, onboardingTargetWeight: string, profileGoalDraft: string,
  profileWeeklyTargetDraft: string, profileReminderTimeDraft: string): string {
  let targetWeight: number = Number(onboardingTargetWeight.trim());
  if (!Number.isNaN(targetWeight) && targetWeight > 0) {
    let distance: number = Number(Math.abs(weight - targetWeight).toFixed(1));
    let direction: string = weight >= targetWeight ? '\u51cf\u8102' : '\u589e\u91cd';
    if (distance < 0.1) {
      return `\u5f53\u524d ${weight.toFixed(1)}kg\uff0c\u5df2\u63a5\u8fd1\u76ee\u6807 ${targetWeight.toFixed(1)}kg\uff0c\u8fdb\u5165\u7ef4\u6301\u8282\u594f\uff0c\u6bcf\u5929 ${profileReminderTimeDraft} \u56de\u770b\u4e00\u6b21\u5373\u53ef\u3002`;
    }
    return `\u5f53\u524d ${weight.toFixed(1)}kg\uff0c\u76ee\u6807 ${targetWeight.toFixed(1)}kg\uff0c\u8fd8\u9700 ${direction} ${distance.toFixed(1)}kg\uff0c\u672c\u5468\u671f\u5f85\u8fdb\u5c55 ${profileWeeklyTargetDraft}kg\uff0c\u6bcf\u5929 ${profileReminderTimeDraft} \u63d0\u9192\u56de\u770b\u3002`;
  }
  return `\u9636\u6bb5\u76ee\u6807\uff1a${profileGoalDraft}\uff0c\u672c\u5468\u671f\u5f85\u8fdb\u5c55 ${profileWeeklyTargetDraft}kg\uff0c\u6bcf\u5929 ${profileReminderTimeDraft} \u63d0\u9192\u56de\u770b\u3002`;
}

export function goalDisplayText(weight: number, onboardingTargetWeight: string, profileGoalText: string): string {
  let targetWeight: number = Number(onboardingTargetWeight.trim());
  if (!Number.isNaN(targetWeight) && targetWeight > 0) {
    let delta: number = Number((weight - targetWeight).toFixed(1));
    if (Math.abs(delta) < 0.1) {
      return '\u8fdb\u5165\u7ef4\u6301\u671f';
    }
    if (delta > 0) {
      return `\u51cf\u8102 ${delta.toFixed(1)}kg`;
    }
    return `\u589e\u91cd ${Math.abs(delta).toFixed(1)}kg`;
  }
  if (profileGoalText.trim().length > 0) {
    return profileGoalText;
  }
  return '\u4fdd\u6301\u8bb0\u5f55';
}

export function profileMenuSubtitle(item: ProfileMenuItem, goalText: string, profileEmail: string): string {
  if (item.id === 2) {
    return `\u76ee\u524d\u76ee\u6807\uff1a${goalText}`;
  }
  if (item.id === 3) {
    return `\u5f53\u524d\u8d26\u53f7\uff1a${profileEmail}`;
  }
  return item.subtitle;
}

export function profileInitial(profileName: string): string {
  if (profileName.length === 0) {
    return 'U';
  }
  return profileName.substring(0, 1);
}
