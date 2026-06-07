const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn } = require('child_process');

const backendRoot = path.join(__dirname, '..');

function createTempDir(prefix) {
  return fs.mkdtempSync(path.join(os.tmpdir(), prefix));
}

function loadUsersModule(options = {}) {
  const tempDir = createTempDir('health-app-users-');
  const configPath = require.resolve('../src/config');
  const usersPath = require.resolve('../src/lib/users');
  delete require.cache[usersPath];
  delete require.cache[configPath];

  const config = require('../src/config');
  config.dataDir = tempDir;
  config.authTokenSecret = options.authTokenSecret || 'test-token-secret';
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

function backupUsersFile() {
  const dataDir = path.join(backendRoot, 'data');
  const usersFile = path.join(dataDir, 'users.json');
  const existed = fs.existsSync(usersFile);
  const original = existed ? fs.readFileSync(usersFile, 'utf8') : '';

  return () => {
    fs.mkdirSync(dataDir, { recursive: true });
    if (existed) {
      fs.writeFileSync(usersFile, original, 'utf8');
      return;
    }
    fs.rmSync(usersFile, { force: true });
  };
}

function waitForServer(child) {
  return new Promise((resolve, reject) => {
    let settled = false;
    const timer = setTimeout(() => {
      if (!settled) {
        settled = true;
        reject(new Error('server did not start in time'));
      }
    }, 5000);

    child.stdout.on('data', (chunk) => {
      if (settled) {
        return;
      }
      if (String(chunk).includes('Backend server listening')) {
        settled = true;
        clearTimeout(timer);
        resolve();
      }
    });

    child.stderr.on('data', (chunk) => {
      if (!settled && String(chunk).includes('EADDRINUSE')) {
        settled = true;
        clearTimeout(timer);
        reject(new Error(String(chunk)));
      }
    });

    child.on('exit', (code) => {
      if (!settled) {
        settled = true;
        clearTimeout(timer);
        reject(new Error(`server exited before ready: ${code}`));
      }
    });
  });
}

async function startServer(t) {
  const restoreUsersFile = backupUsersFile();
  const dataDir = createTempDir('health-app-server-');
  const port = 18000 + Math.floor(Math.random() * 1000);
  const child = spawn(process.execPath, ['src/index.js'], {
    cwd: backendRoot,
    env: {
      ...process.env,
      PORT: String(port),
      DATA_DIR: dataDir,
      AUTH_TOKEN_SECRET: 'test-route-token-secret'
    },
    stdio: ['ignore', 'pipe', 'pipe']
  });

  t.after(() => {
    child.kill();
    restoreUsersFile();
    fs.rmSync(dataDir, { recursive: true, force: true });
  });

  await waitForServer(child);
  return {
    baseUrl: `http://127.0.0.1:${port}`
  };
}

async function postJson(baseUrl, pathName, body, token = '') {
  const headers = {
    'Content-Type': 'application/json'
  };
  if (token.length > 0) {
    headers.Authorization = `Bearer ${token}`;
  }
  const response = await fetch(`${baseUrl}${pathName}`, {
    method: 'POST',
    headers,
    body: JSON.stringify(body)
  });
  const text = await response.text();
  return {
    status: response.status,
    body: text.length > 0 ? JSON.parse(text) : {}
  };
}

test('issued tokens resolve the matching user', () => {
  const users = loadUsersModule();
  try {
    const user = users.registerLocalUser('Alice', 'alice-token@example.com', '12345678');
    const token = users.issueToken(user);
    const resolved = users.resolveUserFromToken(token);

    assert.equal(resolved.id, user.id);
    assert.equal(resolved.email, 'alice-token@example.com');
  } finally {
    users.cleanup();
  }
});

test('legacy base64 tokens cannot be forged from a known user id', () => {
  const users = loadUsersModule();
  try {
    const user = users.registerLocalUser('Bob', 'bob-forged@example.com', '12345678');
    const forged = Buffer.from(`${user.id}:${Date.now()}:fake-nonce`).toString('base64url');

    assert.throws(() => users.resolveUserFromToken(forged), /登录状态已失效|Invalid token|expired/i);
  } finally {
    users.cleanup();
  }
});

test('expired tokens are rejected', () => {
  const users = loadUsersModule({
    authTokenTtlMs: -1000
  });
  try {
    const user = users.registerLocalUser('Cora', 'cora-expired@example.com', '12345678');
    const token = users.issueToken(user);

    assert.throws(() => users.resolveUserFromToken(token), /登录状态已失效|expired/i);
  } finally {
    users.cleanup();
  }
});

test('profile endpoint requires a bearer token', async (t) => {
  const server = await startServer(t);
  const response = await postJson(server.baseUrl, '/api/auth/profile', {
    email: 'missing-token@example.com',
    name: 'Missing Token',
    goalText: 'Keep moving',
    signature: 'No token should not pass'
  });

  assert.equal(response.status, 401);
});

test('profile endpoint updates the authenticated user, not body email', async (t) => {
  const server = await startServer(t);
  const suffix = `${Date.now()}-${Math.floor(Math.random() * 10000)}`;
  const aliceEmail = `alice-${suffix}@example.com`;
  const bobEmail = `bob-${suffix}@example.com`;

  await postJson(server.baseUrl, '/api/auth/register', {
    name: 'Alice',
    email: aliceEmail,
    password: '12345678'
  });
  await postJson(server.baseUrl, '/api/auth/register', {
    name: 'Bob',
    email: bobEmail,
    password: '12345678'
  });
  const login = await postJson(server.baseUrl, '/api/auth/login', {
    email: aliceEmail,
    password: '12345678'
  });

  const response = await postJson(server.baseUrl, '/api/auth/profile', {
    email: bobEmail,
    name: 'Alice Secure',
    goalText: 'Alice goal',
    signature: 'Alice signature'
  }, login.body.token);

  assert.equal(response.status, 200);
  assert.equal(response.body.user.email, aliceEmail);
  assert.equal(response.body.user.name, 'Alice Secure');
});

test('register endpoint validates input before creating an account', async (t) => {
  const server = await startServer(t);

  const blankName = await postJson(server.baseUrl, '/api/auth/register', {
    name: '   ',
    email: 'blank-name@example.com',
    password: '12345678'
  });
  const badEmail = await postJson(server.baseUrl, '/api/auth/register', {
    name: 'Bad Email',
    email: 'not-an-email',
    password: '12345678'
  });
  const shortPassword = await postJson(server.baseUrl, '/api/auth/register', {
    name: 'Short Password',
    email: 'short-password@example.com',
    password: '123'
  });

  assert.equal(blankName.status, 400);
  assert.equal(blankName.body.message, '昵称不能为空');
  assert.equal(badEmail.status, 400);
  assert.equal(badEmail.body.message, '邮箱格式不正确');
  assert.equal(shortPassword.status, 400);
  assert.equal(shortPassword.body.message, '密码至少需要 6 位');
});

test('onboarding endpoint stores decimal profile values for the authenticated user', async (t) => {
  const server = await startServer(t);
  const suffix = `${Date.now()}-${Math.floor(Math.random() * 10000)}`;
  const email = `onboarding-${suffix}@example.com`;

  await postJson(server.baseUrl, '/api/auth/register', {
    name: 'Onboarding',
    email,
    password: '12345678'
  });
  const login = await postJson(server.baseUrl, '/api/auth/login', {
    email,
    password: '12345678'
  });

  const response = await postJson(server.baseUrl, '/api/auth/onboarding', {
    name: 'Onboarding User',
    gender: '男',
    age: 23.4,
    heightCm: 180.5,
    currentWeightKg: 70.25,
    targetWeightKg: 66.75,
    weeklyTargetKg: 0.45
  }, login.body.token);

  assert.equal(response.status, 200);
  assert.equal(response.body.user.name, 'Onboarding User');
  assert.equal(response.body.user.heightCm, 180.5);
  assert.equal(response.body.user.currentWeightKg, 70.25);
  assert.equal(response.body.user.targetWeightKg, 66.75);
  assert.equal(response.body.user.weeklyTargetKg, 0.45);
  assert.equal(response.body.user.onboardingCompleted, true);
});

test('password endpoint rejects invalid updates and lets the new password log in', async (t) => {
  const server = await startServer(t);
  const suffix = `${Date.now()}-${Math.floor(Math.random() * 10000)}`;
  const email = `password-${suffix}@example.com`;

  await postJson(server.baseUrl, '/api/auth/register', {
    name: 'Password User',
    email,
    password: '12345678'
  });
  const login = await postJson(server.baseUrl, '/api/auth/login', {
    email,
    password: '12345678'
  });

  const wrongCurrent = await postJson(server.baseUrl, '/api/auth/password', {
    currentPassword: 'bad-password',
    nextPassword: '87654321'
  }, login.body.token);
  const shortNext = await postJson(server.baseUrl, '/api/auth/password', {
    currentPassword: '12345678',
    nextPassword: '123'
  }, login.body.token);
  const changed = await postJson(server.baseUrl, '/api/auth/password', {
    currentPassword: '12345678',
    nextPassword: '87654321'
  }, login.body.token);
  const oldLogin = await postJson(server.baseUrl, '/api/auth/login', {
    email,
    password: '12345678'
  });
  const newLogin = await postJson(server.baseUrl, '/api/auth/login', {
    email,
    password: '87654321'
  });

  assert.equal(wrongCurrent.status, 400);
  assert.equal(shortNext.status, 400);
  assert.equal(changed.status, 200);
  assert.equal(oldLogin.status, 400);
  assert.equal(newLogin.status, 200);
  assert.equal(newLogin.body.user.email, email);
});
