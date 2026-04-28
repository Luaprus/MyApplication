const fs = require('fs');
const path = require('path');
const config = require('../config');

function ensureStateFile(filePath) {
  const dirPath = path.dirname(filePath);
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
  if (!fs.existsSync(filePath)) {
    fs.writeFileSync(filePath, '{}', 'utf8');
  }
}

function readStateMap(filePath) {
  ensureStateFile(filePath);
  const raw = fs.readFileSync(filePath, 'utf8');
  try {
    const parsed = JSON.parse(raw);
    if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) {
      return parsed;
    }
  } catch (error) {
  }
  return {};
}

function writeStateMap(filePath, stateMap) {
  ensureStateFile(filePath);
  fs.writeFileSync(filePath, JSON.stringify(stateMap, null, 2), 'utf8');
}

function normalizeUserState(state) {
  if (!state || typeof state !== 'object' || Array.isArray(state)) {
    return null;
  }

  const version = typeof state.version === 'number' ? state.version : 1;
  const profile = state.profile && typeof state.profile === 'object' && !Array.isArray(state.profile)
    ? state.profile
    : {};
  const health = state.health && typeof state.health === 'object' && !Array.isArray(state.health)
    ? state.health
    : {};

  return {
    version,
    profile,
    health
  };
}

function createUserStateStore(filePath = path.join(config.dataDir, 'user-states.json')) {
  return {
    load(userId) {
      const stateMap = readStateMap(filePath);
      const userState = stateMap[String(userId || '')];
      return normalizeUserState(userState);
    },
    save(userId, state) {
      const normalizedUserId = String(userId || '').trim();
      if (normalizedUserId.length === 0) {
        throw new Error('缺少用户标识，无法保存状态');
      }

      const normalizedState = normalizeUserState(state);
      if (normalizedState === null) {
        throw new Error('用户状态格式不正确');
      }

      const stateMap = readStateMap(filePath);
      stateMap[normalizedUserId] = normalizedState;
      writeStateMap(filePath, stateMap);
      return normalizedState;
    },
    clear(userId) {
      const normalizedUserId = String(userId || '').trim();
      if (normalizedUserId.length === 0) {
        return;
      }

      const stateMap = readStateMap(filePath);
      delete stateMap[normalizedUserId];
      writeStateMap(filePath, stateMap);
    }
  };
}

const userStateStore = createUserStateStore();

module.exports = {
  createUserStateStore,
  userStateStore
};
