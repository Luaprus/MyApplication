const crypto = require('crypto');
const config = require('../config');

let cachedAccessToken = '';

const localFoods = [
  { code: 'local-apple', name: '苹果', calories: 53, weight: '100g', imageUrl: '', healthLight: 1, isLiquid: false },
  { code: 'local-banana', name: '香蕉', calories: 93, weight: '100g', imageUrl: '', healthLight: 1, isLiquid: false },
  { code: 'local-chicken-breast', name: '鸡胸肉', calories: 133, weight: '100g', imageUrl: '', healthLight: 1, isLiquid: false },
  { code: 'local-rice', name: '米饭', calories: 116, weight: '100g', imageUrl: '', healthLight: 2, isLiquid: false },
  { code: 'local-egg', name: '鸡蛋', calories: 144, weight: '100g', imageUrl: '', healthLight: 1, isLiquid: false },
  { code: 'local-milk', name: '牛奶', calories: 54, weight: '100ml', imageUrl: '', healthLight: 1, isLiquid: true },
  { code: 'local-broccoli', name: '西兰花', calories: 36, weight: '100g', imageUrl: '', healthLight: 1, isLiquid: false },
  { code: 'local-tomato-egg', name: '番茄炒蛋', calories: 93, weight: '100g', imageUrl: '', healthLight: 2, isLiquid: false },
  { code: 'local-oatmeal', name: '燕麦', calories: 338, weight: '100g', imageUrl: '', healthLight: 1, isLiquid: false },
  { code: 'local-yogurt', name: '酸奶', calories: 72, weight: '100g', imageUrl: '', healthLight: 1, isLiquid: true },
  { code: 'local-sweet-potato', name: '红薯', calories: 86, weight: '100g', imageUrl: '', healthLight: 1, isLiquid: false },
  { code: 'local-tofu', name: '豆腐', calories: 84, weight: '100g', imageUrl: '', healthLight: 1, isLiquid: false }
];

function localSearchFoods(keyword) {
  const normalized = String(keyword || '').trim().toLowerCase();
  if (!normalized) {
    return [];
  }
  const matched = localFoods.filter((item) => {
    const name = item.name.toLowerCase();
    return name.includes(normalized) || normalized.includes(name);
  });
  return matched.length > 0 ? matched : localFoods.slice(0, 6);
}

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
    return '';
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
  if (!accessToken) {
    return {
      response: { ok: true, status: 200 },
      data: { foods: localSearchFoods(keyword) }
    };
  }
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
    calories: Math.max(0, Math.round(Number(item.calory ?? item.calories ?? 0))),
    weight: item.weight || '100',
    imageUrl,
    healthLight: typeof item.health_light === 'number'
      ? item.health_light
      : (typeof item.healthLight === 'number' ? item.healthLight : 0),
    isLiquid: item.is_liquid === true || item.isLiquid === true
  };
}

async function searchFoods(keyword, page = 1) {
  if (!keyword || !keyword.trim()) {
    return [];
  }

  let result;
  try {
    result = await requestSearch(keyword.trim(), page, false);
  } catch (error) {
    return localSearchFoods(keyword);
  }
  const errorCode = result.data?.error?.code || 0;
  if ((!result.response.ok || result.data?.success === 0) && (errorCode === 1011 || errorCode === 1012)) {
    try {
      result = await requestSearch(keyword.trim(), page, true);
    } catch (error) {
      return localSearchFoods(keyword);
    }
  }

  if (!result.response.ok || result.data?.success === 0) {
    return localSearchFoods(keyword);
  }

  const foods = Array.isArray(result.data?.foods) ? result.data.foods : [];
  return foods.map(mapFoodItem);
}

module.exports = {
  searchFoods
};
