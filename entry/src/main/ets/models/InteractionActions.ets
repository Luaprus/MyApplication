export type ProfileQuickTagAction = 'goal' | 'steps' | 'meal' | 'exercise' | 'none';

export function resolveProfileQuickTagAction(title: string): ProfileQuickTagAction {
  if (title === '\u76ee\u6807') {
    return 'goal';
  }
  if (title === '\u6b65\u6570') {
    return 'steps';
  }
  if (title === '\u4eca\u65e5\u996e\u98df') {
    return 'meal';
  }
  if (title === '\u8fd0\u52a8\u6d88\u8017') {
    return 'exercise';
  }
  return 'none';
}

export function mealSearchInputMessage(keyword: string, isSearching: boolean): string {
  if (keyword.trim().length === 0) {
    return '\u8bf7\u8f93\u5165\u8981\u641c\u7d22\u7684\u98df\u7269\u540d\u79f0';
  }
  if (isSearching) {
    return '\u6b63\u5728\u641c\u7d22\u4e2d\uff0c\u7a0d\u7b49\u4e00\u4e0b';
  }
  return '';
}
