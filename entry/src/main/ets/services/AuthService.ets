import { backendApiService } from './BackendApiService';

export interface AuthUser {
  id: string;
  name: string;
  email: string;
  membership: string;
  points: number;
  goalText: string;
  signature: string;
  provider: string;
  onboardingCompleted: boolean;
  gender: string;
  age: number;
  heightCm: number;
  currentWeightKg: number;
  targetWeightKg: number;
  weeklyTargetKg: number;
}

interface AuthPayload {
  email?: string;
  password?: string;
  name?: string;
  goalText?: string;
  signature?: string;
  currentPassword?: string;
  nextPassword?: string;
  gender?: string;
  age?: number;
  heightCm?: number;
  currentWeightKg?: number;
  targetWeightKg?: number;
  weeklyTargetKg?: number;
}

export interface AuthResponse {
  token?: string;
  user?: AuthUser;
  message?: string;
}

class AuthService {
  async login(email: string, password: string): Promise<AuthResponse> {
    let payload: AuthPayload = {
      email: email,
      password: password
    };
    let raw: string = await backendApiService.post('/auth/login', JSON.stringify(payload));
    return JSON.parse(raw) as AuthResponse;
  }

  async register(name: string, email: string, password: string): Promise<AuthResponse> {
    let payload: AuthPayload = {
      name: name,
      email: email,
      password: password
    };
    let raw: string = await backendApiService.post('/auth/register', JSON.stringify(payload));
    return JSON.parse(raw) as AuthResponse;
  }

  async updateProfile(authToken: string, email: string, name: string, goalText: string, signature: string): Promise<AuthResponse> {
    let payload: AuthPayload = {
      email: email,
      name: name,
      goalText: goalText,
      signature: signature
    };
    let raw: string = await backendApiService.postWithToken('/auth/profile', JSON.stringify(payload), authToken);
    return JSON.parse(raw) as AuthResponse;
  }

  async completeOnboarding(authToken: string, email: string, name: string, gender: string, age: number, heightCm: number,
    currentWeightKg: number, targetWeightKg: number, weeklyTargetKg: number): Promise<AuthResponse> {
    let payload: AuthPayload = {
      email: email,
      name: name,
      gender: gender,
      age: age,
      heightCm: heightCm,
      currentWeightKg: currentWeightKg,
      targetWeightKg: targetWeightKg,
      weeklyTargetKg: weeklyTargetKg
    };
    let raw: string = await backendApiService.postWithToken('/auth/onboarding', JSON.stringify(payload), authToken);
    return JSON.parse(raw) as AuthResponse;
  }

  async changePassword(authToken: string, email: string, currentPassword: string, nextPassword: string): Promise<AuthResponse> {
    let payload: AuthPayload = {
      email: email,
      currentPassword: currentPassword,
      nextPassword: nextPassword
    };
    let raw: string = await backendApiService.postWithToken('/auth/password', JSON.stringify(payload), authToken);
    return JSON.parse(raw) as AuthResponse;
  }
}

export const authService: AuthService = new AuthService();
