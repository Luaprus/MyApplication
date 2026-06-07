import { AppSessionState } from './AppState';

const OFFLINE_DEMO_TOKEN: string = 'offline-demo-token';

export function sanitizeSessionForPersistence(session: AppSessionState): AppSessionState {
  return {
    isAuthenticated: session.isAuthenticated,
    authMode: session.authMode,
    authToken: restorePersistedAuthToken(session),
    authHint: session.authHint,
    authProvider: session.authProvider,
    loginEmail: session.loginEmail,
    needsOnboarding: session.needsOnboarding,
    onboardingName: session.onboardingName,
    onboardingGender: session.onboardingGender,
    onboardingAge: session.onboardingAge,
    onboardingHeight: session.onboardingHeight,
    onboardingCurrentWeight: session.onboardingCurrentWeight,
    onboardingTargetWeight: session.onboardingTargetWeight,
    onboardingWeeklyTarget: session.onboardingWeeklyTarget
  };
}

export function restorePersistedAuthToken(session: AppSessionState): string {
  return typeof session.authToken === 'string' ? session.authToken : '';
}

export function shouldRestoreAuthenticatedSession(session: AppSessionState): boolean {
  return session.isAuthenticated && restorePersistedAuthToken(session).trim().length > 0;
}

export function hasSyncableAuthToken(authToken: string): boolean {
  let token: string = authToken.trim();
  return token.length > 0 && token !== OFFLINE_DEMO_TOKEN;
}
