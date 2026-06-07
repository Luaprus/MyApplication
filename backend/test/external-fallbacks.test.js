const assert = require('node:assert/strict');
const test = require('node:test');

function reloadService(serviceName, envOverrides) {
  const keys = [
    'DEEPSEEK_API_KEY',
    'DOUBAO_API_KEY',
    'DOUBAO_ENDPOINT_ID',
    'BOOHEE_APP_ID',
    'BOOHEE_APP_KEY'
  ];
  const previous = {};
  for (const key of keys) {
    previous[key] = process.env[key];
    process.env[key] = envOverrides[key] ?? '';
  }

  delete require.cache[require.resolve('../src/config')];
  delete require.cache[require.resolve(`../src/services/${serviceName}`)];
  const service = require(`../src/services/${serviceName}`);

  for (const key of keys) {
    if (previous[key] === undefined) {
      delete process.env[key];
    } else {
      process.env[key] = previous[key];
    }
  }
  return service;
}

test('DeepSeek service returns local demo advice when API key is missing', async () => {
  const { chatWithDeepSeek } = reloadService('deepseek', {});

  const reply = await chatWithDeepSeek([{ role: 'user', content: '今天晚餐怎么吃？' }]);

  assert.match(reply, /本地演示|未配置/);
  assert.match(reply, /晚餐|饮食|蛋白/);
});

test('Doubao food vision returns a demo recognition result when model config is missing', async () => {
  const { analyzeFoodImage } = reloadService('doubao', {});

  const result = await analyzeFoodImage('abc', 'image/png');

  assert.equal(typeof result.foodName, 'string');
  assert.ok(result.foodName.length > 0);
  assert.ok(result.estimatedCalories > 0);
  assert.match(result.summary, /未配置|演示/);
});

test('Boohee search returns local foods when credentials are missing', async () => {
  const { searchFoods } = reloadService('boohee', {});

  const foods = await searchFoods('苹果', 1);

  assert.ok(foods.length > 0);
  assert.ok(foods.some((item) => item.name.includes('苹果')));
  assert.ok(foods[0].calories > 0);
});
