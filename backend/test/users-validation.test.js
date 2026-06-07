const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');

function createTempDir(prefix) {
  return fs.mkdtempSync(path.join(os.tmpdir(), prefix));
}

function loadUsersModule(options = {}) {
  const tempDir = createTempDir('health-app-validation-');
  const configPath = require.resolve('../src/config');
  const usersPath = require.resolve('../src/lib/users');
  delete require.cache[usersPath];
  delete require.cache[configPath];

  const config = require('../src/config');
  config.dataDir = tempDir;
  config.authTokenSecret = options.authTokenSecret || 'validation-token-secret';
  config.authTokenTtlMs = options.authTokenTtlMs ?? 60 * 60 * 1000;
  delete require.cache[usersPath];

  const users = require('../src/lib/users');
  return {
    ...users,
    cleanup() {
      delete require.cache[usersPath];
      delete require.cache[configPath];
      fs.rmSync(tempDir, { recursive: true, force: true });
    }
  };
}

function registerBaselineUser(users, suffix = Date.now()) {
  return users.registerLocalUser('Alice', `alice-${suffix}@example.com`, '12345678');
}

test('registration rejects blank nickname, malformed email, and short password', () => {
  const users = loadUsersModule();
  try {
    assert.throws(() => users.registerLocalUser('', 'blank-name@example.com', '12345678'), /昵称不能为空/);
    assert.throws(() => users.registerLocalUser('Bad Email', 'not-an-email', '12345678'), /邮箱格式不正确/);
    assert.throws(() => users.registerLocalUser('Short Password', 'short-password@example.com', '123'), /密码至少需要 6 位/);
  } finally {
    users.cleanup();
  }
});

test('registration trims nickname and lowercases trimmed email', () => {
  const users = loadUsersModule();
  try {
    const user = users.registerLocalUser('  Alice  ', '  Alice.Case@Example.COM  ', '12345678');

    assert.equal(user.name, 'Alice');
    assert.equal(user.email, 'alice.case@example.com');
  } finally {
    users.cleanup();
  }
});

test('login accepts surrounding email whitespace and remains case-insensitive', () => {
  const users = loadUsersModule();
  try {
    users.registerLocalUser('Alice', 'alice-login@example.com', '12345678');

    const user = users.loginLocalUser('  ALICE-LOGIN@EXAMPLE.COM  ', '12345678');

    assert.equal(user.email, 'alice-login@example.com');
  } finally {
    users.cleanup();
  }
});

test('onboarding preserves decimal precision for height and weights', () => {
  const users = loadUsersModule();
  try {
    const user = registerBaselineUser(users, 'decimal');

    const updated = users.completeLocalUserOnboardingById(user.id, {
      name: 'Alice',
      gender: '女',
      age: 18.8,
      heightCm: 168.5,
      currentWeightKg: 61.94,
      targetWeightKg: 57.96,
      weeklyTargetKg: 0.34
    });

    assert.equal(updated.age, 19);
    assert.equal(updated.heightCm, 168.5);
    assert.equal(updated.currentWeightKg, 61.94);
    assert.equal(updated.targetWeightKg, 57.96);
    assert.equal(updated.weeklyTargetKg, 0.34);
    assert.equal(updated.goalText, '57.96kg 目标');
    assert.equal(updated.signature, '计划每周稳定推进 0.34kg');
  } finally {
    users.cleanup();
  }
});

test('onboarding rejects non-finite numbers and out-of-range weekly target', () => {
  const users = loadUsersModule();
  try {
    const user = registerBaselineUser(users, 'range');

    assert.throws(() => users.completeLocalUserOnboardingById(user.id, {
      name: 'Alice',
      gender: '女',
      age: Number.NaN,
      heightCm: 168,
      currentWeightKg: 62,
      targetWeightKg: 58,
      weeklyTargetKg: 0.3
    }), /年龄请填 12~80 之间/);

    assert.throws(() => users.completeLocalUserOnboardingById(user.id, {
      name: 'Alice',
      gender: '女',
      age: 18,
      heightCm: 168,
      currentWeightKg: 62,
      targetWeightKg: 58,
      weeklyTargetKg: 2.01
    }), /每周目标请填 0~2kg 之间/);
  } finally {
    users.cleanup();
  }
});
