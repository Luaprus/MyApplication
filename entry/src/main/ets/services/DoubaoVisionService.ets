import { backendApiService } from './BackendApiService';

interface FoodRecognitionPayload {
  foodName?: string;
  estimatedCalories?: number | string;
  summary?: string;
}

export interface FoodRecognitionResult {
  foodName: string;
  estimatedCalories: number;
  summary: string;
  rawReply: string;
}

class DoubaoVisionService {
  async analyzeFoodImage(base64Image: string, mimeType: string): Promise<FoodRecognitionResult> {
    let payload: string = JSON.stringify({
      base64Image: base64Image,
      mimeType: mimeType
    });
    let raw: string = await backendApiService.post('/ai/vision/food', payload);
    return JSON.parse(raw) as FoodRecognitionResult;
  }
}

export const doubaoVisionService: DoubaoVisionService = new DoubaoVisionService();
