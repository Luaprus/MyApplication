const crypto = require('crypto');
const config = require('../config');

let cachedAccessToken = '';

function buildSign(timestamp) {
  const source = `app_id${config.boohee.appId}timestamp${timestamp}`;
  const wrapped = `${config.boohee.appKey}${source}${config.boohee.appKey}`;
  return crypto.createHash('md5').update(wrapped).digest('hex');
}

async function ensureAccessToken(forceRefresh = false) {
  if (!forceRefresh && cachedAccessToken) {
    return cachedAccessToken;
  }
  if (!config.boohee.appId || !config.boohee.appKey) {
    throw new Error('\u670d\u52a1\u7aef\u672a\u914d\u7f6e\u8584\u8377\u98df\u7269\u5e93');
  }

  const timestamp = Math.floor(Date.now() / 1000).toString();
  const body = new URLSearchParams({
    app_id: config.boohee.appId,
    timestamp,
    sign: buildSign(timestamp)
  }).toString();

  const response = await fetch(`${config.boohee.baseUrl}/api/v2/access_tokens`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json'
    },
    body
  });

  const data = await response.json();
  if (!response.ok || !data?.access_token) {
    throw new Error(data?.error?.message || data?.message || '\u8584\u8377 token \u83b7\u53d6\u5931\u8d25');
  }
  cachedAccessToken = data.access_token;
  return cachedAccessToken;
}

async function requestSearch(keyword, page, forceRefresh = false) {
  const accessToken = await ensureAccessToken(forceRefresh);
  const url = `${config.boohee.baseUrl}/api/v1/foods/search?q=${encodeURIComponent(keyword)}&page=${page}`;
  const response = await fetch(url, {
    headers: {
      'Accept': 'application/json',
      'AccessToken': accessToken
    }
  });
  const data = await response.json();
  return { response, data };
}

function mapFoodItem(item) {
  let imageUrl = item.thumb_image_url || '';
  if (imageUrl.startsWith('http://')) {
    imageUrl = `https://${imageUrl.slice(7)}`;
  }
  return {
    code: item.code || '',
    name: item.name || '\u672a\u547d\u540d\u98df\u7269',
    calories: Math.max(0, Math.round(Number(item.calory || 0))),
    weight: item.weight || '100',
    imageUrl,
    healthLight: typeof item.health_light === 'number' ? item.health_light : 0,
    isLiquid: item.is_liquid === true
  };
}

async function searchFoods(keyword, page = 1) {
  if (!keyword || !keyword.trim()) {
    return [];
  }

  let result = await requestSearch(keyword.trim(), page, false);
  const errorCode = result.data?.error?.code || 0;
  if ((!result.response.ok || result.data?.success === 0) && (errorCode === 1011 || errorCode === 1012)) {
    result = await requestSearch(keyword.trim(), page, true);
  }

  if (!result.response.ok || result.data?.success === 0) {
    throw new Error(result.data?.error?.message || result.data?.message || `\u8584\u8377 HTTP ${result.response.status}`);
  }

  const foods = Array.isArray(result.data?.foods) ? result.data.foods : [];
  return foods.map(mapFoodItem);
}

module.exports = {
  searchFoods
};
