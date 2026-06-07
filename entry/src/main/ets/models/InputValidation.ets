export function decimalText(value: string): string {
  let normalized: string = value.replace('\u3002', '.');
  let result: string = '';
  let hasDot: boolean = false;
  for (let index = 0; index < normalized.length; index++) {
    let char: string = normalized.charAt(index);
    if (char >= '0' && char <= '9') {
      result += char;
    } else if (char === '.' && !hasDot) {
      result += char;
      hasDot = true;
    }
  }
  return result;
}

export function integerText(value: string): string {
  let result: string = '';
  for (let index = 0; index < value.length; index++) {
    let char: string = value.charAt(index);
    if (char >= '0' && char <= '9') {
      result += char;
    }
  }
  return result;
}

export function isDecimalDraftValid(value: string): boolean {
  return /^\d*\.?\d{0,2}$/.test(value);
}
