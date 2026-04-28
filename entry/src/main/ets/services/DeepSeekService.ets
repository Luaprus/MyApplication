import { backendApiService } from './BackendApiService';

export type DeepSeekRole = 'system' | 'user' | 'assistant';

export interface DeepSeekMessage {
  role: DeepSeekRole;
  content: string;
}

interface DeepSeekResponse {
  reply?: string;
}

class DeepSeekService {
  async chat(messages: DeepSeekMessage[]): Promise<string> {
    let payload: string = JSON.stringify({
      messages: messages,
    });
    let raw: string = await this.withTimeout(
      backendApiService.post('/ai/chat', payload),
      35000,
      'AI \u56de\u590d\u8d85\u65f6\uff0c\u8bf7\u68c0\u67e5 backend \u548c\u7f51\u7edc\u8fde\u63a5\u540e\u91cd\u8bd5'
    );
    let responseBody: DeepSeekResponse = this.parseResponse(raw);
    let content: string = responseBody.reply?.trim() ?? '';
    if (content.length === 0) {
      throw new Error('\u670d\u52a1\u7aef\u6ca1\u6709\u8fd4\u56de AI \u5185\u5bb9');
    }
    return content;
  }

  private parseResponse(result: string): DeepSeekResponse {
    return JSON.parse(result) as DeepSeekResponse;
  }

  private withTimeout(task: Promise<string>, timeoutMs: number, timeoutMessage: string): Promise<string> {
    return new Promise((resolve: (value: string) => void, reject: (reason?: Error) => void) => {
      let settled: boolean = false;
      let timerId: number = setTimeout(() => {
        if (settled) {
          return;
        }
        settled = true;
        reject(new Error(timeoutMessage));
      }, timeoutMs);

      task.then((result: string) => {
        if (settled) {
          return;
        }
        settled = true;
        clearTimeout(timerId);
        resolve(result);
      }).catch((error: Error) => {
        if (settled) {
          return;
        }
        settled = true;
        clearTimeout(timerId);
        reject(error);
      });
    });
  }
}

export const deepSeekService: DeepSeekService = new DeepSeekService();
