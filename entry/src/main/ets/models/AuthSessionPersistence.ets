import { AppSessionState } from './AppState';

export function sanitizeSessionForPersistence(session: AppSessionState): AppSessionState {
  return {
    isAuthenticated: session.isAuthenticated,
    authMode: session.authMode,
    authToken: '',
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
  return '';
}
