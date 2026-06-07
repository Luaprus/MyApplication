import { describe, it, expect } from '@ohos/hypium';
import { AppSessionState } from '../main/ets/models/AppState';
import { hasSyncableAuthToken, restorePersistedAuthToken, sanitizeSessionForPersistence, shouldRestoreAuthenticatedSession } from '../main/ets/models/AuthSessionPersistence';

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
    it('sanitizeSessionForPersistence should keep login state and server token', 0, () => {
      let session: AppSessionState = sanitizeSessionForPersistence(buildSession('real-server-token'));

      expect(session.isAuthenticated).assertTrue();
      expect(session.loginEmail).assertEqual('alice@example.com');
      expect(session.authToken).assertEqual('real-server-token');
    });

    it('restorePersistedAuthToken should reuse persisted login token', 0, () => {
      expect(restorePersistedAuthToken(buildSession('real-server-token'))).assertEqual('real-server-token');
      expect(restorePersistedAuthToken(buildSession('offline-demo-token'))).assertEqual('offline-demo-token');
    });

    it('shouldRestoreAuthenticatedSession should reject stale login state without token', 0, () => {
      expect(shouldRestoreAuthenticatedSession(buildSession('real-server-token'))).assertTrue();
      expect(shouldRestoreAuthenticatedSession(buildSession('offline-demo-token'))).assertTrue();
      expect(shouldRestoreAuthenticatedSession(buildSession(''))).assertFalse();

      let session: AppSessionState = buildSession('real-server-token');
      session.authToken = undefined;
      expect(shouldRestoreAuthenticatedSession(session)).assertFalse();
    });

    it('hasSyncableAuthToken should only accept real backend tokens', 0, () => {
      expect(hasSyncableAuthToken('real-server-token')).assertTrue();
      expect(hasSyncableAuthToken('  real-server-token  ')).assertTrue();
      expect(hasSyncableAuthToken('')).assertFalse();
      expect(hasSyncableAuthToken('offline-demo-token')).assertFalse();
    });
  });
}
