const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn } = require('child_process');

const { createUserStateStore } = require('../src/lib/user-state');

const backendRoot = path.join(__dirname, '..');

function createTempDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'health-app-state-'));
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
      if (!settled && String(chunk).includes('Backend server listening')) {
        settled = true;
        clearTimeout(timer);
        resolve();
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
  const dataDir = createTempDir();
  const port = 19000 + Math.floor(Math.random() * 1000);
  const child = spawn(process.execPath, ['src/index.js'], {
    cwd: backendRoot,
    env: {
      ...process.env,
      PORT: String(port),
      DATA_DIR: dataDir,
      AUTH_TOKEN_SECRET: 'state-route-token-secret'
    },
    stdio: ['ignore', 'pipe', 'pipe']
  });

  t.after(() => {
    child.kill();
    fs.rmSync(dataDir, { recursive: true, force: true });
  });

  await waitForServer(child);
  return {
    baseUrl: `http://127.0.0.1:${port}`
  };
}

async function jsonRequest(baseUrl, pathName, method, body, token = '') {
  const headers = {
    'Content-Type': 'application/json'
  };
  if (token.length > 0) {
    headers.Authorization = `Bearer ${token}`;
  }
  const response = await fetch(`${baseUrl}${pathName}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body)
  });
  const text = await response.text();
  return {
    status: response.status,
    body: text.length > 0 ? JSON.parse(text) : {}
  };
}

async function postJson(baseUrl, pathName, body, token = '') {
  return jsonRequest(baseUrl, pathName, 'POST', body, token);
}

async function putJson(baseUrl, pathName, body, token = '') {
  return jsonRequest(baseUrl, pathName, 'PUT', body, token);
}

async function getJson(baseUrl, pathName, token = '') {
  return jsonRequest(baseUrl, pathName, 'GET', undefined, token);
}

test('loads null when the user has no saved state yet', () => {
  const tempDir = createTempDir();
  const store = createUserStateStore(path.join(tempDir, 'user-states.json'));

  const state = store.load('user-a');

  assert.equal(state, null);
});

test('saves and loads state for the matching user only', () => {
  const tempDir = createTempDir();
  const store = createUserStateStore(path.join(tempDir, 'user-states.json'));

  store.save('user-a', {
    version: 1,
    profile: {
      profileName: 'Alice'
    },
    health: {
      calories: 520
    }
  });
  store.save('user-b', {
    version: 1,
    profile: {
      profileName: 'Bob'
    },
    health: {
      calories: 860
    }
  });

  const userAState = store.load('user-a');
  const userBState = store.load('user-b');

  assert.deepEqual(userAState, {
    version: 1,
    profile: {
      profileName: 'Alice'
    },
    health: {
      calories: 520
    }
  });
  assert.deepEqual(userBState, {
    version: 1,
    profile: {
      profileName: 'Bob'
    },
    health: {
      calories: 860
    }
  });
});

test('save rejects missing user id and invalid state shape', () => {
  const tempDir = createTempDir();
  const store = createUserStateStore(path.join(tempDir, 'user-states.json'));

  assert.throws(() => store.save('  ', {
    version: 1,
    profile: {},
    health: {}
  }), /缺少用户标识/);
  assert.throws(() => store.save('user-a', null), /用户状态格式不正确/);
  assert.throws(() => store.save('user-a', []), /用户状态格式不正确/);
});

test('load treats corrupted state file as empty instead of crashing', () => {
  const tempDir = createTempDir();
  const stateFile = path.join(tempDir, 'user-states.json');
  fs.mkdirSync(tempDir, { recursive: true });
  fs.writeFileSync(stateFile, '{not-valid-json', 'utf8');
  const store = createUserStateStore(stateFile);

  assert.equal(store.load('user-a'), null);
});

test('state endpoints require auth, reject invalid state, and isolate users', async (t) => {
  const server = await startServer(t);
  const suffix = `${Date.now()}-${Math.floor(Math.random() * 10000)}`;
  const aliceEmail = `state-alice-${suffix}@example.com`;
  const bobEmail = `state-bob-${suffix}@example.com`;

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
  const aliceLogin = await postJson(server.baseUrl, '/api/auth/login', {
    email: aliceEmail,
    password: '12345678'
  });
  const bobLogin = await postJson(server.baseUrl, '/api/auth/login', {
    email: bobEmail,
    password: '12345678'
  });

  const unauthenticated = await getJson(server.baseUrl, '/api/user/state');
  const invalid = await putJson(server.baseUrl, '/api/user/state', {
    state: []
  }, aliceLogin.body.token);
  const saved = await putJson(server.baseUrl, '/api/user/state', {
    state: {
      version: 1,
      profile: {
        profileName: 'Alice'
      },
      health: {
        weight: 61.9
      }
    }
  }, aliceLogin.body.token);
  const aliceState = await getJson(server.baseUrl, '/api/user/state', aliceLogin.body.token);
  const bobState = await getJson(server.baseUrl, '/api/user/state', bobLogin.body.token);

  assert.equal(unauthenticated.status, 401);
  assert.equal(invalid.status, 400);
  assert.equal(saved.status, 200);
  assert.equal(aliceState.body.state.profile.profileName, 'Alice');
  assert.equal(aliceState.body.state.health.weight, 61.9);
  assert.equal(bobState.body.state, null);
});
