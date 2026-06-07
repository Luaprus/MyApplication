const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const config = require('../config');

const usersFilePath = path.join(config.dataDir, 'users.json');

function ensureUsersFile() {
  if (!fs.existsSync(config.dataDir)) {
    fs.mkdirSync(config.dataDir, { recursive: true });
  }
  if (!fs.existsSync(usersFilePath)) {
    fs.writeFileSync(usersFilePath, '[]', 'utf8');
  }
}

function readUsers() {
  ensureUsersFile();
  const raw = fs.readFileSync(usersFilePath, 'utf8');
  try {
    const users = JSON.parse(raw);
    return Array.isArray(users) ? users : [];
  } catch (error) {
    return [];
  }
}

function writeUsers(users) {
  ensureUsersFile();
  fs.writeFileSync(usersFilePath, JSON.stringify(users, null, 2), 'utf8');
}

function createPasswordHash(password, salt) {
  return crypto.scryptSync(password, salt, 64).toString('hex');
}

function buildLocalUser(name, email, password, options = {}) {
  const salt = crypto.randomBytes(16).toString('hex');
  const isDemoUser = Boolean(options.isDemoUser);
  return {
    id: crypto.randomUUID(),
    name,
    email: email.toLowerCase(),
    passwordSalt: salt,
    passwordHash: createPasswordHash(password, salt),
    membership: isDemoUser ? '\u767d\u91d1\u4f1a\u5458' : '\u57fa\u7840\u7248',
    points: isDemoUser ? 1200 : 0,
    goalText: isDemoUser ? '\u51cf\u8102 4kg' : '',
    signature: isDemoUser ? '\u8fde\u7eed\u8bb0\u5f55 6 \u5929\uff0c\u6b63\u5728\u7a33\u6b65\u63a8\u8fdb' : '',
    provider: 'local',
    onboardingCompleted: isDemoUser,
    gender: isDemoUser ? '\u5973' : '',
    age: isDemoUser ? 24 : 0,
    heightCm: isDemoUser ? 165 : 0,
    currentWeightKg: isDemoUser ? 61.9 : 0,
    targetWeightKg: isDemoUser ? 57.9 : 0,
    weeklyTargetKg: isDemoUser ? 0.3 : 0,
    createdAt: new Date().toISOString()
  };
}

function normalizeUserRecord(user) {
  const normalizedUser = { ...user };

  if (typeof normalizedUser.membership !== 'string' || normalizedUser.membership.trim().length === 0) {
    normalizedUser.membership = normalizedUser.email === config.demoUser.email.toLowerCase() ? '\u767d\u91d1\u4f1a\u5458' : '\u57fa\u7840\u7248';
  }
  if (typeof normalizedUser.points !== 'number') {
    normalizedUser.points = normalizedUser.email === config.demoUser.email.toLowerCase() ? 1200 : 0;
  }
  if (typeof normalizedUser.goalText !== 'string') {
    normalizedUser.goalText = '';
  }
  if (typeof normalizedUser.signature !== 'string') {
    normalizedUser.signature = '';
  }
  if (typeof normalizedUser.onboardingCompleted !== 'boolean') {
    normalizedUser.onboardingCompleted = true;
  }
  if (typeof normalizedUser.gender !== 'string') {
    normalizedUser.gender = '';
  }
  if (typeof normalizedUser.age !== 'number') {
    normalizedUser.age = 0;
  }
  if (typeof normalizedUser.heightCm !== 'number') {
    normalizedUser.heightCm = 0;
  }
  if (typeof normalizedUser.currentWeightKg !== 'number') {
    normalizedUser.currentWeightKg = 0;
  }
  if (typeof normalizedUser.targetWeightKg !== 'number') {
    normalizedUser.targetWeightKg = 0;
  }
  if (typeof normalizedUser.weeklyTargetKg !== 'number') {
    normalizedUser.weeklyTargetKg = 0;
  }
  return normalizedUser;
}

function sanitizeUser(user) {
  const normalizedUser = normalizeUserRecord(user);
  return {
    id: normalizedUser.id,
    name: normalizedUser.name,
    email: normalizedUser.email,
    membership: normalizedUser.membership,
    points: normalizedUser.points,
    goalText: normalizedUser.goalText,
    signature: normalizedUser.signature,
    provider: normalizedUser.provider,
    onboardingCompleted: normalizedUser.onboardingCompleted,
    gender: normalizedUser.gender,
    age: normalizedUser.age,
    heightCm: normalizedUser.heightCm,
    currentWeightKg: normalizedUser.currentWeightKg,
    targetWeightKg: normalizedUser.targetWeightKg,
    weeklyTargetKg: normalizedUser.weeklyTargetKg
  };
}

function ensureDemoUser() {
  const users = readUsers();
  const existing = users.find((item) => item.email === config.demoUser.email.toLowerCase());
  if (existing) {
    const normalizedExisting = normalizeUserRecord(existing);
    normalizedExisting.onboardingCompleted = true;
    normalizedExisting.goalText = normalizedExisting.goalText || '\u51cf\u8102 4kg';
    normalizedExisting.signature = normalizedExisting.signature || '\u8fde\u7eed\u8bb0\u5f55 6 \u5929\uff0c\u6b63\u5728\u7a33\u6b65\u63a8\u8fdb';
    normalizedExisting.membership = '\u767d\u91d1\u4f1a\u5458';
    normalizedExisting.points = 1200;
    if (normalizedExisting.age <= 0) {
      normalizedExisting.age = 24;
    }
    if (normalizedExisting.heightCm <= 0) {
      normalizedExisting.heightCm = 165;
    }
    if (normalizedExisting.currentWeightKg <= 0) {
      normalizedExisting.currentWeightKg = 61.9;
    }
    if (normalizedExisting.targetWeightKg <= 0) {
      normalizedExisting.targetWeightKg = 57.9;
    }
    if (normalizedExisting.weeklyTargetKg <= 0) {
      normalizedExisting.weeklyTargetKg = 0.3;
    }
    const nextUsers = users.map((item) => item.email === normalizedExisting.email ? normalizedExisting : item);
    writeUsers(nextUsers);
    return normalizedExisting;
  }
  const demoUser = buildLocalUser(config.demoUser.name, config.demoUser.email, config.demoUser.password, {
    isDemoUser: true
  });
  users.push(demoUser);
  writeUsers(users);
  return demoUser;
}

function registerLocalUser(name, email, password) {
  const users = readUsers();
  const normalizedName = String(name || '').trim();
  const normalizedEmail = String(email || '').trim().toLowerCase();
  const normalizedPassword = String(password || '');

  if (normalizedName.length === 0) {
    throw new Error('\u6635\u79f0\u4e0d\u80fd\u4e3a\u7a7a');
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail)) {
    throw new Error('\u90ae\u7bb1\u683c\u5f0f\u4e0d\u6b63\u786e');
  }
  if (normalizedPassword.trim().length < 6) {
    throw new Error('\u5bc6\u7801\u81f3\u5c11\u9700\u8981 6 \u4f4d');
  }

  const existing = users.find((item) => item.email === normalizedEmail);
  if (existing) {
    throw new Error('\u8be5\u90ae\u7bb1\u5df2\u7ecf\u6ce8\u518c\u8fc7\u4e86');
  }
  const user = buildLocalUser(normalizedName, normalizedEmail, normalizedPassword);
  users.push(user);
  writeUsers(users);
  return sanitizeUser(user);
}

function loginLocalUser(email, password) {
  const users = readUsers();
  const normalizedEmail = String(email || '').trim().toLowerCase();
  const user = users.find((item) => item.email === normalizedEmail && item.provider === 'local');
  if (!user) {
    throw new Error('\u8d26\u53f7\u6216\u5bc6\u7801\u4e0d\u6b63\u786e');
  }
  const passwordHash = createPasswordHash(password, user.passwordSalt);
  if (passwordHash !== user.passwordHash) {
    throw new Error('\u8d26\u53f7\u6216\u5bc6\u7801\u4e0d\u6b63\u786e');
  }
  return sanitizeUser(user);
}

function findUserById(id) {
  const normalizedId = String(id || '').trim();
  if (normalizedId.length === 0) {
    return null;
  }
  const users = readUsers();
  const user = users.find((item) => item.id === normalizedId);
  return user ? normalizeUserRecord(user) : null;
}

function tokenSecret() {
  const secret = String(config.authTokenSecret || '').trim();
  return secret.length > 0 ? secret : 'myapplication-dev-token-secret';
}

function tokenTtlMs() {
  const ttl = Number(config.authTokenTtlMs);
  return Number.isFinite(ttl) ? ttl : 7 * 24 * 60 * 60 * 1000;
}

function encodeTokenPayload(payload) {
  return Buffer.from(JSON.stringify(payload), 'utf8').toString('base64url');
}

function signTokenPayload(encodedPayload) {
  return crypto.createHmac('sha256', tokenSecret()).update(encodedPayload).digest('base64url');
}

function signaturesMatch(actual, expected) {
  const actualBuffer = Buffer.from(String(actual || ''), 'utf8');
  const expectedBuffer = Buffer.from(String(expected || ''), 'utf8');
  return actualBuffer.length === expectedBuffer.length && crypto.timingSafeEqual(actualBuffer, expectedBuffer);
}

function resolveUserFromToken(token) {
  const normalizedToken = String(token || '').trim();
  if (normalizedToken.length === 0) {
    throw new Error('\u672a\u63d0\u4f9b\u767b\u5f55\u4ee4\u724c');
  }

  try {
    const parts = normalizedToken.split('.');
    if (parts.length !== 2) {
      throw new Error('invalid');
    }

    const [encodedPayload, signature] = parts;
    const expectedSignature = signTokenPayload(encodedPayload);
    if (!signaturesMatch(signature, expectedSignature)) {
      throw new Error('invalid');
    }

    const payload = JSON.parse(Buffer.from(encodedPayload, 'base64url').toString('utf8'));
    const userId = String(payload.sub || '').trim();
    const expiresAt = Number(payload.exp);
    if (userId.length === 0 || !Number.isFinite(expiresAt)) {
      throw new Error('invalid');
    }
    if (expiresAt <= Date.now()) {
      throw new Error('expired');
    }

    const user = findUserById(userId);
    if (!user) {
      throw new Error('missing');
    }
    return sanitizeUser(user);
  } catch (error) {
    throw new Error('\u767b\u5f55\u72b6\u6001\u5df2\u5931\u6548\uff0c\u8bf7\u91cd\u65b0\u767b\u5f55');
  }
}

function findLocalUserByEmail(users, email) {
  const normalizedEmail = String(email || '').toLowerCase();
  return users.find((item) => item.email === normalizedEmail && item.provider === 'local');
}

function findLocalUserByIdForUpdate(users, id, message) {
  const normalizedId = String(id || '').trim();
  const user = users.find((item) => item.id === normalizedId && item.provider === 'local');
  if (!user) {
    throw new Error(message);
  }
  return user;
}

function applyProfileUpdate(user, payload) {
  const nextName = String(payload.name || '').trim();
  const nextGoalText = String(payload.goalText || '').trim();
  const nextSignature = String(payload.signature || '').trim();

  if (nextName.length === 0) {
    throw new Error('\u6635\u79f0\u4e0d\u80fd\u4e3a\u7a7a');
  }
  if (nextGoalText.length === 0) {
    throw new Error('\u76ee\u6807\u5185\u5bb9\u4e0d\u80fd\u4e3a\u7a7a');
  }
  if (nextSignature.length === 0) {
    throw new Error('\u4e2a\u6027\u7b7e\u540d\u4e0d\u80fd\u4e3a\u7a7a');
  }

  user.name = nextName;
  user.goalText = nextGoalText;
  user.signature = nextSignature;
}

function updateLocalUserProfile(email, payload) {
  const users = readUsers();
  const user = findLocalUserByEmail(users, email);
  if (!user) {
    throw new Error('\u672a\u627e\u5230\u53ef\u66f4\u65b0\u7684\u8d26\u53f7');
  }

  applyProfileUpdate(user, payload);
  writeUsers(users);
  return sanitizeUser(user);
}

function updateLocalUserProfileById(id, payload) {
  const users = readUsers();
  const user = findLocalUserByIdForUpdate(users, id, '\u672a\u627e\u5230\u53ef\u66f4\u65b0\u7684\u8d26\u53f7');
  applyProfileUpdate(user, payload);
  writeUsers(users);
  return sanitizeUser(user);
}

function applyOnboardingUpdate(user, payload) {
  const nextName = String(payload.name || '').trim();
  const nextGender = String(payload.gender || '').trim();
  const nextAge = Number(payload.age || 0);
  const nextHeightCm = Number(payload.heightCm || 0);
  const nextCurrentWeightKg = Number(payload.currentWeightKg || 0);
  const nextTargetWeightKg = Number(payload.targetWeightKg || 0);
  const nextWeeklyTargetKg = Number(payload.weeklyTargetKg || 0);

  if (nextName.length === 0) {
    throw new Error('\u6635\u79f0\u4e0d\u80fd\u4e3a\u7a7a');
  }
  if (nextGender !== '\u7537' && nextGender !== '\u5973') {
    throw new Error('\u8bf7\u9009\u62e9\u6027\u522b');
  }
  if (!Number.isFinite(nextAge) || nextAge < 12 || nextAge > 80) {
    throw new Error('\u5e74\u9f84\u8bf7\u586b 12~80 \u4e4b\u95f4');
  }
  if (!Number.isFinite(nextHeightCm) || nextHeightCm < 120 || nextHeightCm > 230) {
    throw new Error('\u8eab\u9ad8\u8bf7\u586b 120~230cm');
  }
  if (!Number.isFinite(nextCurrentWeightKg) || nextCurrentWeightKg < 30 || nextCurrentWeightKg > 200) {
    throw new Error('\u5f53\u524d\u4f53\u91cd\u8bf7\u586b 30~200kg');
  }
  if (!Number.isFinite(nextTargetWeightKg) || nextTargetWeightKg < 30 || nextTargetWeightKg > 200) {
    throw new Error('\u76ee\u6807\u4f53\u91cd\u8bf7\u586b 30~200kg');
  }
  if (!Number.isFinite(nextWeeklyTargetKg) || nextWeeklyTargetKg <= 0 || nextWeeklyTargetKg > 2) {
    throw new Error('\u6bcf\u5468\u76ee\u6807\u8bf7\u586b 0~2kg \u4e4b\u95f4');
  }

  user.name = nextName;
  user.gender = nextGender;
  user.age = Number(nextAge.toFixed(0));
  user.heightCm = Number(nextHeightCm.toFixed(1));
  user.currentWeightKg = Number(nextCurrentWeightKg.toFixed(2));
  user.targetWeightKg = Number(nextTargetWeightKg.toFixed(2));
  user.weeklyTargetKg = Number(nextWeeklyTargetKg.toFixed(2));
  user.goalText = `${Number(nextTargetWeightKg.toFixed(2))}kg \u76ee\u6807`;
  user.signature = `\u8ba1\u5212\u6bcf\u5468\u7a33\u5b9a\u63a8\u8fdb ${Number(nextWeeklyTargetKg.toFixed(2))}kg`;
  user.membership = '\u57fa\u7840\u7248';
  user.points = 0;
  user.onboardingCompleted = true;
}

function completeLocalUserOnboarding(email, payload) {
  const users = readUsers();
  const user = findLocalUserByEmail(users, email);
  if (!user) {
    throw new Error('\u672a\u627e\u5230\u53ef\u521d\u59cb\u5316\u7684\u8d26\u53f7');
  }

  applyOnboardingUpdate(user, payload);
  writeUsers(users);
  return sanitizeUser(user);
}

function completeLocalUserOnboardingById(id, payload) {
  const users = readUsers();
  const user = findLocalUserByIdForUpdate(users, id, '\u672a\u627e\u5230\u53ef\u521d\u59cb\u5316\u7684\u8d26\u53f7');
  applyOnboardingUpdate(user, payload);
  writeUsers(users);
  return sanitizeUser(user);
}

function applyPasswordUpdate(user, currentPassword, nextPassword) {
  const currentHash = createPasswordHash(currentPassword, user.passwordSalt);
  if (currentHash !== user.passwordHash) {
    throw new Error('\u5f53\u524d\u5bc6\u7801\u4e0d\u6b63\u786e');
  }
  if (String(nextPassword).trim().length < 6) {
    throw new Error('\u65b0\u5bc6\u7801\u81f3\u5c11\u9700\u8981 6 \u4f4d');
  }

  const nextSalt = crypto.randomBytes(16).toString('hex');
  user.passwordSalt = nextSalt;
  user.passwordHash = createPasswordHash(nextPassword, nextSalt);
}

function updateLocalUserPassword(email, currentPassword, nextPassword) {
  const users = readUsers();
  const user = findLocalUserByEmail(users, email);
  if (!user) {
    throw new Error('\u672a\u627e\u5230\u53ef\u66f4\u65b0\u7684\u8d26\u53f7');
  }

  applyPasswordUpdate(user, currentPassword, nextPassword);
  writeUsers(users);
}

function updateLocalUserPasswordById(id, currentPassword, nextPassword) {
  const users = readUsers();
  const user = findLocalUserByIdForUpdate(users, id, '\u672a\u627e\u5230\u53ef\u66f4\u65b0\u7684\u8d26\u53f7');
  applyPasswordUpdate(user, currentPassword, nextPassword);
  writeUsers(users);
}

function issueToken(user) {
  const issuedAt = Date.now();
  const payload = {
    sub: user.id,
    iat: issuedAt,
    exp: issuedAt + tokenTtlMs(),
    nonce: crypto.randomUUID()
  };
  const encodedPayload = encodeTokenPayload(payload);
  return `${encodedPayload}.${signTokenPayload(encodedPayload)}`;
}

module.exports = {
  ensureDemoUser,
  registerLocalUser,
  loginLocalUser,
  findUserById,
  resolveUserFromToken,
  updateLocalUserProfile,
  updateLocalUserProfileById,
  completeLocalUserOnboarding,
  completeLocalUserOnboardingById,
  updateLocalUserPassword,
  updateLocalUserPasswordById,
  issueToken
};
