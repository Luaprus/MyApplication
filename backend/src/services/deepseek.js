const config = require('../config');

function wait(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

function parseDeepSeekError(data, status) {
  const code = data?.code;
  const message = data?.message || data?.error?.message || '';
  if (code === 2300007) {
    return 'DeepSeek \u670d\u52a1\u6682\u65f6\u4e0d\u53ef\u7528\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5';
  }
  if (message) {
    return message;
  }
  return `DeepSeek HTTP ${status}`;
}

async function chatWithDeepSeek(messages) {
  if (!config.deepseek.apiKey) {
    throw new Error('\u670d\u52a1\u7aef\u672a\u914d\u7f6e DeepSeek API Key');
  }

  let lastError = null;

  for (let attempt = 0; attempt < 3; attempt += 1) {
    try {
      const response = await fetch(config.deepseek.apiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${config.deepseek.apiKey}`
        },
        body: JSON.stringify({
          model: config.deepseek.model,
          messages,
          stream: false
        })
      });

      const data = await response.json();
      if (!response.ok) {
        const errorMessage = parseDeepSeekError(data, response.status);
        if ((data?.code === 2300007 || response.status >= 500) && attempt < 2) {
          await wait(800 * (attempt + 1));
          continue;
        }
        throw new Error(errorMessage);
      }

      const reply = data?.choices?.[0]?.message?.content?.trim() || '';
      if (!reply) {
        throw new Error('DeepSeek \u8fd4\u56de\u4e86\u7a7a\u5185\u5bb9');
      }
      return reply;
    } catch (error) {
      lastError = error;
      if (attempt < 2) {
        await wait(800 * (attempt + 1));
        continue;
      }
    }
  }

  if (lastError instanceof Error) {
    throw lastError;
  }
  throw new Error('DeepSeek \u8c03\u7528\u5931\u8d25');
}

module.exports = {
  chatWithDeepSeek
};
