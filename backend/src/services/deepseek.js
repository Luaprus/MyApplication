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

function localDemoReply(messages, reason = 'DeepSeek API Key 未配置') {
  const userMessages = Array.isArray(messages)
    ? messages.filter((message) => message?.role === 'user')
    : [];
  const question = String(userMessages[userMessages.length - 1]?.content || '').trim();
  const topic = question || '今天的健康记录';

  return [
    `（本地演示回复：${reason}）`,
    `关于“${topic}”，可以先按一个稳妥的减脂节奏来做：`,
    '1. 每餐保留优质蛋白，比如鸡蛋、鱼虾、鸡胸肉或豆腐。',
    '2. 主食不要完全不吃，优先选择米饭半碗、燕麦、红薯这类更稳定的来源。',
    '3. 晚上如果饿，先补水，再选酸奶、水果或少量坚果，避免临睡前高油高糖。',
    '4. 明天继续记录体重、饮水和运动，AI 周报会更容易给出个性化建议。'
  ].join('\n');
}

async function chatWithDeepSeek(messages) {
  if (!config.deepseek.apiKey) {
    return localDemoReply(messages);
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
    return localDemoReply(messages, `DeepSeek 调用失败：${lastError.message}`);
  }
  return localDemoReply(messages, 'DeepSeek 调用失败');
}

module.exports = {
  chatWithDeepSeek
};
