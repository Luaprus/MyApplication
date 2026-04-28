import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { AppPersistentState } from '../models/AppState';

class AppStateStore {
  private readonly storeName: string = 'health_app_state';
  private readonly stateKey: string = 'state';

  async load(context: common.Context): Promise<AppPersistentState | null> {
    try {
      let store = await preferences.getPreferences(context, {
        name: this.storeName
      });
      let rawValue = await store.get(this.stateKey, '');
      if (typeof rawValue !== 'string' || rawValue.trim().length === 0) {
        return null;
      }

      try {
        return JSON.parse(rawValue) as AppPersistentState;
      } catch (error) {
        return null;
      }
    } catch (error) {
      return null;
    }
  }

  async save(context: common.Context, state: AppPersistentState): Promise<void> {
    try {
      let store = await preferences.getPreferences(context, {
        name: this.storeName
      });
      await store.put(this.stateKey, JSON.stringify(state));
      await store.flush();
    } catch (error) {
    }
  }

  async clear(context: common.Context): Promise<void> {
    try {
      let store = await preferences.getPreferences(context, {
        name: this.storeName
      });
      await store.delete(this.stateKey);
      await store.flush();
    } catch (error) {
    }
  }
}

export const appStateStore: AppStateStore = new AppStateStore();
