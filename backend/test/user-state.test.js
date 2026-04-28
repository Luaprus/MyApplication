const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');

const { createUserStateStore } = require('../src/lib/user-state');

function createTempDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'health-app-state-'));
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
