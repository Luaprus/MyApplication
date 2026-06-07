export interface FoodScanSource {
  uri: string;
  useDemoImage: boolean;
  status: string;
}

export const DEMO_FOOD_IMAGE_BASE64: string =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=';

export function foodScanSourceFromUri(uri: string): FoodScanSource {
  let safeUri: string = uri.trim();
  if (safeUri.length > 0) {
    return {
      uri: safeUri,
      useDemoImage: false,
      status: '\u6b63\u5728\u8bfb\u53d6\u7167\u7247...'
    };
  }

  return {
    uri: '',
    useDemoImage: true,
    status: '\u56fe\u5e93\u672a\u6253\u5f00\uff0c\u5df2\u4f7f\u7528\u6f14\u793a\u56fe\u7247...'
  };
}
