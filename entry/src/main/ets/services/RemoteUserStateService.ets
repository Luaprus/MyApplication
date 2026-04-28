import { backendApiService } from './BackendApiService';
import { AppRemoteState } from '../models/AppState';

interface RemoteUserStateResponse {
  state?: AppRemoteState;
  message?: string;
}

interface RemoteUserStatePayload {
  state: AppRemoteState;
}

class RemoteUserStateService {
  async fetch(authToken: string): Promise<AppRemoteState | null> {
    let raw: string = await backendApiService.getWithToken('/user/state', authToken);
    let response: RemoteUserStateResponse = JSON.parse(raw) as RemoteUserStateResponse;
    return response.state ?? null;
  }

  async save(authToken: string, state: AppRemoteState): Promise<void> {
    let payload: RemoteUserStatePayload = {
      state: state
    };
    await backendApiService.putWithToken('/user/state', JSON.stringify(payload), authToken);
  }
}

export const remoteUserStateService: RemoteUserStateService = new RemoteUserStateService();
