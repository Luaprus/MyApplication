import { WaterRecordItem } from './AppState';

export interface WaterCardDisplayState {
  total: number;
  valueText: string;
  subtitleText: string;
  buttonText: string;
}

export function buildWaterCardDisplayStateFromTotal(total: number, goalMl: number,
  latestRecord: WaterRecordItem | null): WaterCardDisplayState {
  let subtitleText: string = '';

  if (latestRecord !== null) {
    let remaining: number = Math.max(0, goalMl - total);
    if (remaining <= 0) {
      subtitleText = `${latestRecord.drinkName} ${latestRecord.amount}ml\uff0c\u4eca\u65e5\u8865\u6c34\u5df2\u8fbe\u6807`;
    } else {
      subtitleText = `${latestRecord.drinkName} ${latestRecord.amount}ml\uff0c\u8fd8\u5dee ${remaining}ml \u8fbe\u6210\u4eca\u65e5\u76ee\u6807`;
    }
  } else {
    subtitleText = `\u4eca\u65e5\u76ee\u6807 ${goalMl}ml\uff0c\u73b0\u5728\u53ef\u4ee5\u5148\u8bb0\u5f55\u7b2c\u4e00\u676f`;
  }

  return {
    total: total,
    valueText: `${total} ml`,
    subtitleText: subtitleText,
    buttonText: total > 0 ? '\u518d\u8bb0\u4e00\u676f' : '\u53bb\u8bb0\u5f55'
  };
}

export function sumWaterAmounts(records: WaterRecordItem[]): number {
  let total: number = 0;
  for (let index = 0; index < records.length; index++) {
    total += records[index].amount;
  }
  return total;
}

export function buildWaterCardDisplayState(records: WaterRecordItem[], goalMl: number): WaterCardDisplayState {
  let total: number = sumWaterAmounts(records);
  return buildWaterCardDisplayStateFromTotal(total, goalMl, records.length > 0 ? records[0] : null);
}
