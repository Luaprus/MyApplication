import { describe, it, expect } from '@ohos/hypium';
import { decimalText, integerText, isDecimalDraftValid } from '../main/ets/models/InputValidation';

export default function inputValidationTest() {
  describe('inputValidationTest', () => {
    it('decimalText should keep one decimal point and convert Chinese period', 0, () => {
      expect(decimalText('0.4')).assertEqual('0.4');
      expect(decimalText('0。4')).assertEqual('0.4');
      expect(decimalText('61..95kg')).assertEqual('61.95');
      expect(decimalText('abc57.9')).assertEqual('57.9');
    });

    it('integerText should remove non-digits for age fields', 0, () => {
      expect(integerText('18')).assertEqual('18');
      expect(integerText('18.5')).assertEqual('185');
      expect(integerText('a2岁4')).assertEqual('24');
    });

    it('isDecimalDraftValid should enforce precision and empty draft rules', 0, () => {
      expect(isDecimalDraftValid('')).assertTrue();
      expect(isDecimalDraftValid('62')).assertTrue();
      expect(isDecimalDraftValid('62.5')).assertTrue();
      expect(isDecimalDraftValid('62.55')).assertTrue();
      expect(isDecimalDraftValid('62.555')).assertFalse();
      expect(isDecimalDraftValid('62..5')).assertFalse();
      expect(isDecimalDraftValid('62a')).assertFalse();
    });
  });
}
