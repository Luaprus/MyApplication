import { describe, it, expect } from '@ohos/hypium';
import { AppSessionState } from '../main/ets/models/AppState';
import { restorePersistedAuthToken, sanitizeSessionForPersistence } from '../main/ets/models/AuthSessionPersistence';

function buildSession(token: string): AppSessionState {
  return {
    isAuthenticated: true,
    authMode: 'login',
    authToken: token,
    authHint: '\u6b22\u8fce\u56de\u6765',
    authProvider: 'local',
    loginEmail: 'alice@example.com',
    needsOnboarding: false,
    onboardingName: '',
    onboardingGender: '',
    onboardingAge: '',
    onboardingHeight: '',
    onboardingCurrentWeight: '',
    onboardingTargetWeight: '',
    onboardingWeeklyTarget: ''
  };
}

export default function authSessionPersistenceTest() {
  describe('authSessionPersistenceTest', () => {
    it('sanitizeSessionForPersistence should keep login state but clear token', 0, () => {
      let session: AppSessionState = sanitizeSessionForPersistence(buildSession('real-server-token'));

      expect(session.isAuthenticated).assertTrue();
      expect(session.loginEmail).assertEqual('alice@example.com');
      expect(session.authToken).assertEqual('');
    });

    it('restorePersistedAuthToken should never reuse a token from Preferences', 0, () => {
      expect(restorePersistedAuthToken(buildSession('real-server-token'))).assertEqual('');
      expect(restorePersistedAuthToken(buildSession('offline-demo-token'))).assertEqual('');
    });
  });
}
