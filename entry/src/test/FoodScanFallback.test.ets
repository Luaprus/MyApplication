import { describe, it, expect } from '@ohos/hypium';
import { foodScanSourceFromUri, FoodScanSource } from '../main/ets/models/FoodScanFallback';

export default function foodScanFallbackTest() {
  describe('foodScanFallbackTest', () => {
    it('foodScanSourceFromUri should use selected photo when picker returns uri', 0, () => {
      let source: FoodScanSource = foodScanSourceFromUri('file://photo.jpg');

      expect(source.useDemoImage).assertFalse();
      expect(source.uri).assertEqual('file://photo.jpg');
      expect(source.status).assertEqual('\u6b63\u5728\u8bfb\u53d6\u7167\u7247...');
    });

    it('foodScanSourceFromUri should fall back to demo image when picker is unavailable', 0, () => {
      let source: FoodScanSource = foodScanSourceFromUri('');

      expect(source.useDemoImage).assertTrue();
      expect(source.uri).assertEqual('');
      expect(source.status).assertEqual('\u56fe\u5e93\u672a\u6253\u5f00\uff0c\u5df2\u4f7f\u7528\u6f14\u793a\u56fe\u7247...');
    });
  });
}
