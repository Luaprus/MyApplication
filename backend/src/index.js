const express = require('express');
const cors = require('cors');
const config = require('./config');
const {
  ensureDemoUser,
  registerLocalUser,
  loginLocalUser,
  updateLocalUserProfileById,
  completeLocalUserOnboardingById,
  updateLocalUserPasswordById,
  issueToken,
  resolveUserFromToken
} = require('./lib/users');
const { userStateStore } = require('./lib/user-state');
const { chatWithDeepSeek } = require('./services/deepseek');
const { analyzeFoodImage } = require('./services/doubao');
const { searchFoods } = require('./services/boohee');

ensureDemoUser();

const app = express();

app.use(cors({
  origin: config.clientOrigin === '*' ? true : config.clientOrigin.split(','),
  credentials: true
}));
app.use(express.json({ limit: '10mb' }));

app.get('/api/health', (req, res) => {
  res.json({
    ok: true
  });
});

function requireAuth(req, res, next) {
  try {
    const authorization = String(req.headers.authorization || '');
    if (!authorization.startsWith('Bearer ')) {
      throw new Error('\u8bf7\u5148\u767b\u5f55\u540e\u518d\u540c\u6b65\u6570\u636e');
    }
    const token = authorization.slice(7).trim();
    req.authUser = resolveUserFromToken(token);
    next();
  } catch (error) {
    res.status(401).json({
      message: error instanceof Error ? error.message : '\u767b\u5f55\u72b6\u6001\u5df2\u5931\u6548\uff0c\u8bf7\u91cd\u65b0\u767b\u5f55'
    });
  }
}

app.post('/api/auth/register', (req, res, next) => {
  try {
    const { name, email, password } = req.body || {};
    const user = registerLocalUser(String(name || ''), String(email || ''), String(password || ''));
    res.json({
      message: '\u6ce8\u518c\u6210\u529f',
      user
    });
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/login', (req, res, next) => {
  try {
    const { email, password } = req.body || {};
    const user = loginLocalUser(String(email || ''), String(password || ''));
    res.json({
      token: issueToken(user),
      user
    });
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/profile', requireAuth, (req, res, next) => {
  try {
    const { name, goalText, signature } = req.body || {};
    const user = updateLocalUserProfileById(req.authUser.id, {
      name: String(name || ''),
      goalText: String(goalText || ''),
      signature: String(signature || '')
    });
    res.json({
      message: '\u4e2a\u4eba\u4fe1\u606f\u5df2\u66f4\u65b0',
      user
    });
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/onboarding', requireAuth, (req, res, next) => {
  try {
    const { name, gender, age, heightCm, currentWeightKg, targetWeightKg, weeklyTargetKg } = req.body || {};
    const user = completeLocalUserOnboardingById(req.authUser.id, {
      name: String(name || ''),
      gender: String(gender || ''),
      age: Number(age || 0),
      heightCm: Number(heightCm || 0),
      currentWeightKg: Number(currentWeightKg || 0),
      targetWeightKg: Number(targetWeightKg || 0),
      weeklyTargetKg: Number(weeklyTargetKg || 0)
    });
    res.json({
      message: '\u57fa\u7840\u4fe1\u606f\u5df2\u521d\u59cb\u5316',
      user
    });
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/password', requireAuth, (req, res, next) => {
  try {
    const { currentPassword, nextPassword } = req.body || {};
    updateLocalUserPasswordById(req.authUser.id, String(currentPassword || ''), String(nextPassword || ''));
    res.json({
      message: '\u5bc6\u7801\u4fee\u6539\u6210\u529f'
    });
  } catch (error) {
    next(error);
  }
});

app.get('/api/user/state', requireAuth, (req, res, next) => {
  try {
    const state = userStateStore.load(req.authUser.id);
    res.json({ state });
  } catch (error) {
    next(error);
  }
});

app.put('/api/user/state', requireAuth, (req, res, next) => {
  try {
    const state = userStateStore.save(req.authUser.id, req.body?.state);
    res.json({
      message: '\u7528\u6237\u72b6\u6001\u5df2\u540c\u6b65',
      state
    });
  } catch (error) {
    next(error);
  }
});

app.post('/api/ai/chat', async (req, res, next) => {
  try {
    const messages = Array.isArray(req.body?.messages) ? req.body.messages : [];
    const reply = await chatWithDeepSeek(messages);
    res.json({ reply });
  } catch (error) {
    next(error);
  }
});

app.post('/api/ai/vision/food', async (req, res, next) => {
  try {
    const base64Image = String(req.body?.base64Image || '');
    const mimeType = String(req.body?.mimeType || '');
    const result = await analyzeFoodImage(base64Image, mimeType);
    res.json(result);
  } catch (error) {
    next(error);
  }
});

app.get('/api/foods/search', async (req, res, next) => {
  try {
    const keyword = String(req.query.q || '');
    const page = Number(req.query.page || 1);
    const foods = await searchFoods(keyword, page);
    res.json({ foods });
  } catch (error) {
    next(error);
  }
});

app.use((error, req, res, next) => {
  const message = error instanceof Error ? error.message : 'Server error';
  const status = message.includes('\u5c1a\u672a\u914d\u7f6e') ? 501 : 400;
  res.status(status).json({
    message
  });
});

app.listen(config.port, () => {
  console.log(`Backend server listening on http://localhost:${config.port}`);
});
