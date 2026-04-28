import { backendApiService } from './BackendApiService';

export interface BooheeFoodItem {
  code: string;
  name: string;
  calories: number;
  weight: string;
  imageUrl: string;
  healthLight: number;
  isLiquid: boolean;
}

interface BooheeFoodSearchResponse {
  foods?: Array<BooheeFoodItem>;
}

class BooheeFoodService {
  async searchFoods(keyword: string, page: number = 1): Promise<Array<BooheeFoodItem>> {
    let normalizedKeyword: string = keyword.trim();
    if (normalizedKeyword.length === 0) {
      return [];
    }
    let raw: string = await backendApiService.get(`/foods/search?q=${encodeURIComponent(normalizedKeyword)}&page=${page}`);
    let parsed: BooheeFoodSearchResponse = JSON.parse(raw) as BooheeFoodSearchResponse;
    return parsed.foods ?? [];
  }
}

export const booheeFoodService: BooheeFoodService = new BooheeFoodService();
