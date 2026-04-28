export function formatClock(date: Date = new Date()): string {
  let hour: string = date.getHours().toString().padStart(2, '0');
  let minute: string = date.getMinutes().toString().padStart(2, '0');
  return `${hour}:${minute}`;
}

export function dayKeyFromDate(date: Date): string {
  let year: string = date.getFullYear().toString();
  let month: string = (date.getMonth() + 1).toString().padStart(2, '0');
  let day: string = date.getDate().toString().padStart(2, '0');
  return `${year}-${month}-${day}`;
}

export function currentDayKey(): string {
  return dayKeyFromDate(new Date());
}

export function dateFromDayKey(dayKey: string): Date {
  let parts: string[] = dayKey.split('-');
  if (parts.length !== 3) {
    return new Date();
  }
  let year: number = Number(parts[0]);
  let month: number = Number(parts[1]);
  let day: number = Number(parts[2]);
  return new Date(year, month - 1, day);
}

export function dayKeyFromOffset(offsetDays: number): string {
  let date: Date = new Date();
  date.setDate(date.getDate() + offsetDays);
  return dayKeyFromDate(date);
}

export function currentWeekDayKeys(): string[] {
  let today: Date = new Date();
  let currentDay: number = today.getDay();
  let mondayOffset: number = currentDay === 0 ? -6 : 1 - currentDay;
  let monday: Date = new Date(today.getTime());
  monday.setDate(today.getDate() + mondayOffset);

  let keys: string[] = [];
  for (let index = 0; index < 7; index++) {
    let day: Date = new Date(monday.getTime());
    day.setDate(monday.getDate() + index);
    keys.push(dayKeyFromDate(day));
  }
  return keys;
}

export function monthTitleFromDayKey(dayKey: string): string {
  let date: Date = dateFromDayKey(dayKey);
  return `${date.getFullYear()} \u5e74 ${date.getMonth() + 1} \u6708`;
}
