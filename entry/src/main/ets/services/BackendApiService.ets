import { http } from '@kit.NetworkKit';
import { BACKEND_API_BASE_URL } from '../config/BackendConfig';

class BackendApiService {
  async get(path: string): Promise<string> {
    return this.request(path, http.RequestMethod.GET, '', '');
  }

  async post(path: string, body: string): Promise<string> {
    return this.request(path, http.RequestMethod.POST, body, '');
  }

  async postWithToken(path: string, body: string, authToken: string): Promise<string> {
    return this.request(path, http.RequestMethod.POST, body, authToken);
  }

  async getWithToken(path: string, authToken: string): Promise<string> {
    return this.request(path, http.RequestMethod.GET, '', authToken);
  }

  async putWithToken(path: string, body: string, authToken: string): Promise<string> {
    return this.request(path, http.RequestMethod.PUT, body, authToken);
  }

  private async request(path: string, method: http.RequestMethod, body: string, authToken: string): Promise<string> {
    let urls: Array<string> = this.buildCandidateUrls(path);
    let lastErrorMessage: string = '';

    for (let index: number = 0; index < urls.length; index++) {
      try {
        return await this.requestOnce(urls[index], method, body, authToken);
      } catch (error) {
        let currentErrorMessage: string = this.errorMessage(error);
        if (lastErrorMessage.length === 0 || this.shouldReplaceError(lastErrorMessage, currentErrorMessage)) {
          lastErrorMessage = currentErrorMessage;
        }
      }
    }

    if (lastErrorMessage.length > 0) {
      throw new Error(lastErrorMessage);
    }
    throw new Error('\u65e0\u6cd5\u8fde\u63a5\u5230\u540e\u7aef\u670d\u52a1');
  }

  private shouldReplaceError(previousMessage: string, nextMessage: string): boolean {
    if (previousMessage.includes('\u8d85\u65f6')) {
      return false;
    }
    if (nextMessage.includes('\u8d85\u65f6')) {
      return true;
    }
    return true;
  }

  private async requestOnce(url: string, method: http.RequestMethod, body: string, authToken: string): Promise<string> {
    let client = http.createHttp();
    let response: http.HttpResponse;
    let timeouts: RequestTimeoutConfig = this.timeoutConfig(url);
    let requestOptions: http.HttpRequestOptions = {
      method: method,
      header: this.requestHeaders(authToken),
      extraData: body,
      connectTimeout: timeouts.connectTimeout,
      readTimeout: timeouts.readTimeout
    };

    try {
      try {
        response = await client.request(url, requestOptions);
      } catch (error) {
        throw new Error(this.errorMessage(error));
      }

      let raw: string = typeof response.result === 'string' ? response.result : JSON.stringify(response.result);
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(this.parseMessage(raw, response.responseCode));
      }
      return raw;
    } finally {
      client.destroy();
    }
  }

  private requestHeaders(authToken: string): RequestHeaders {
    let headers: RequestHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };
    if (authToken.trim().length > 0) {
      headers.Authorization = `Bearer ${authToken}`;
    }
    return headers;
  }

  private timeoutConfig(url: string): RequestTimeoutConfig {
    if (url.includes('/ai/vision/food')) {
      return {
        connectTimeout: 12000,
        readTimeout: 45000
      };
    }
    if (url.includes('/ai/chat')) {
      return {
        connectTimeout: 10000,
        readTimeout: 30000
      };
    }
    return {
      connectTimeout: 8000,
      readTimeout: 12000
    };
  }

  private buildCandidateUrls(path: string): Array<string> {
    let urls: Array<string> = [`${BACKEND_API_BASE_URL}${path}`];
    if (BACKEND_API_BASE_URL.includes('10.0.2.2')) {
      urls.push(`${BACKEND_API_BASE_URL.replace('10.0.2.2', '127.0.0.1')}${path}`);
      urls.push(`${BACKEND_API_BASE_URL.replace('10.0.2.2', 'localhost')}${path}`);
    } else if (BACKEND_API_BASE_URL.includes('127.0.0.1')) {
      urls.push(`${BACKEND_API_BASE_URL.replace('127.0.0.1', '10.0.2.2')}${path}`);
      urls.push(`${BACKEND_API_BASE_URL.replace('127.0.0.1', 'localhost')}${path}`);
    } else if (BACKEND_API_BASE_URL.includes('localhost')) {
      urls.push(`${BACKEND_API_BASE_URL.replace('localhost', '10.0.2.2')}${path}`);
      urls.push(`${BACKEND_API_BASE_URL.replace('localhost', '127.0.0.1')}${path}`);
    }
    return this.uniqueUrls(urls);
  }

  private uniqueUrls(urls: Array<string>): Array<string> {
    let normalized: Array<string> = [];
    urls.forEach((item: string) => {
      if (!normalized.includes(item)) {
        normalized.push(item);
      }
    });
    return normalized;
  }

  private parseMessage(raw: string, code: number): string {
    try {
      let parsed: BackendErrorResponse = JSON.parse(raw) as BackendErrorResponse;
      return parsed.message ?? `HTTP ${code}`;
    } catch (error) {
      return raw.length > 0 ? raw : `HTTP ${code}`;
    }
  }

  private errorMessage(error: Object | string): string {
    if (error instanceof Error) {
      return this.normalizeNetworkMessage(error.message);
    }
    if (typeof error === 'string') {
      return this.normalizeNetworkMessage(error);
    }
    return JSON.stringify(error);
  }

  private normalizeNetworkMessage(message: string): string {
    if (message.includes('2300028') || message.includes('timeout') || message.includes('Time out')) {
      return '\u8bf7\u6c42\u540e\u7aef\u8d85\u65f6\uff0c\u8bf7\u7a0d\u540e\u518d\u8bd5';
    }
    if (message.includes('2300007') || message.includes("Couldn't connect to server")) {
      return '\u65e0\u6cd5\u8fde\u63a5\u5230\u540e\u7aef\u670d\u52a1\uff0c\u8bf7\u68c0\u67e5 backend \u662f\u5426\u5df2\u542f\u52a8';
    }
    return message;
  }
}

interface BackendErrorResponse {
  message?: string;
}

interface RequestTimeoutConfig {
  connectTimeout: number;
  readTimeout: number;
}

interface RequestHeaders {
  'Content-Type': string;
  'Accept': string;
  Authorization?: string;
}

export const backendApiService: BackendApiService = new BackendApiService();
