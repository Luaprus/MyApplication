const path = require('path');
const dotenv = require('dotenv');

dotenv.config({ path: path.join(__dirname, '..', '.env') });

function numberFromEnv(value, fallback) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

const config = {
  port: Number(process.env.PORT || 5200),
  clientOrigin: process.env.CLIENT_ORIGIN || '*',
  dataDir: process.env.DATA_DIR ? path.resolve(process.env.DATA_DIR) : path.join(__dirname, '..', 'data'),
  authTokenSecret: process.env.AUTH_TOKEN_SECRET || 'myapplication-dev-token-secret',
  authTokenTtlMs: numberFromEnv(process.env.AUTH_TOKEN_TTL_MS, 7 * 24 * 60 * 60 * 1000),
  deepseek: {
    apiUrl: process.env.DEEPSEEK_API_URL || 'https://api.deepseek.com/chat/completions',
    apiKey: process.env.DEEPSEEK_API_KEY || '',
    model: process.env.DEEPSEEK_MODEL || 'deepseek-chat'
  },
  doubao: {
    apiUrl: process.env.DOUBAO_API_URL || 'https://ark.cn-beijing.volces.com/api/v3/chat/completions',
    apiKey: process.env.DOUBAO_API_KEY || '',
    endpointId: process.env.DOUBAO_ENDPOINT_ID || ''
  },
  boohee: {
    baseUrl: process.env.BOOHEE_BASE_URL || 'https://fc.boohee.com',
    appId: process.env.BOOHEE_APP_ID || '',
    appKey: process.env.BOOHEE_APP_KEY || ''
  },
  demoUser: {
    name: process.env.DEMO_NAME || '\u5c0f\u660e',
    email: process.env.DEMO_EMAIL || 'demo@health.app',
    password: process.env.DEMO_PASSWORD || '12345678'
  }
};

module.exports = config;
