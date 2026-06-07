const config = require('../config');

function wait(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

function extractJson(rawReply) {
  const cleaned = String(rawReply || '').trim();
  const start = cleaned.indexOf('{');
  const end = cleaned.lastIndexOf('}');
  if (start >= 0 && end > start) {
    return cleaned.slice(start, end + 1);
  }
  return cleaned;
}

function normalizeCalories(value) {
  if (typeof value === 'number') {
    return Math.max(0, Math.round(value));
  }
  if (typeof value === 'string') {
    const numeric = value.replace(/[^0-9.]/g, '');
    if (numeric) {
      return Math.max(0, Math.round(Number(numeric)));
    }
  }
  return 0;
}

function fallbackFoodResult(rawReply) {
  const text = String(rawReply || '').trim();
  const match = text.match(/(\d{2,4})/);
  const calories = match ? Number(match[1]) : 0;
  const lines = text.split('\n');
  const foodName = lines[0] && lines[0].trim() ? lines[0].trim() : '\u672a\u8bc6\u522b\u5177\u4f53\u98df\u7269';
  return {
    foodName,
    estimatedCalories: calories,
    summary: text || '\u672a\u83b7\u53d6\u5230\u6709\u6548\u8bc6\u522b\u7ed3\u679c\u3002',
    rawReply
  };
}

function parseFoodResult(rawReply) {
  try {
    const parsed = JSON.parse(extractJson(rawReply));
    return {
      foodName: typeof parsed.foodName === 'string' && parsed.foodName.trim()
        ? parsed.foodName.trim()
        : '\u672a\u8bc6\u522b\u5177\u4f53\u98df\u7269',
      estimatedCalories: normalizeCalories(parsed.estimatedCalories),
      summary: typeof parsed.summary === 'string' && parsed.summary.trim()
        ? parsed.summary.trim()
        : '\u57fa\u4e8e\u56fe\u7247\u5185\u5bb9\u7ed9\u51fa\u7684\u4f30\u7b97\u7ed3\u679c\u3002',
      rawReply
    };
  } catch (error) {
    return fallbackFoodResult(rawReply);
  }
}

function demoFoodResult(reason = '未配置豆包视觉模型') {
  return {
    foodName: '演示识别：家常餐食',
    estimatedCalories: 420,
    summary: `${reason}，已使用本地演示估算。真实拍照识别需要在 backend/.env 配置 DOUBAO_API_KEY 和 DOUBAO_ENDPOINT_ID。`,
    rawReply: reason
  };
}

function normalizeMimeType(mimeType) {
  const value = String(mimeType || '').trim().toLowerCase();
  if (value === 'image/png' || value === 'image/webp' || value === 'image/heic' || value === 'image/heif') {
    return value;
  }
  return 'image/jpeg';
}

function parseDoubaoError(data, status) {
  const code = data?.error?.code;
  const message = data?.error?.message || '';
  if (code === 'InvalidParameter' && message) {
    return message;
  }
  if (String(data?.code || '') === '2300007' || message.includes("Couldn't connect to server")) {
    return '豆包视觉服务暂时不可用，请稍后重试';
  }
  if (message) {
    return message;
  }
  return `豆包 HTTP ${status}`;
}

async function analyzeFoodImage(base64Image, mimeType) {
  if (!config.doubao.apiKey || !config.doubao.endpointId) {
    return demoFoodResult();
  }

  let normalizedMimeType = normalizeMimeType(mimeType);
  let lastError = null;

  for (let attempt = 0; attempt < 3; attempt += 1) {
    try {
      const response = await fetch(config.doubao.apiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${config.doubao.apiKey}`
        },
        body: JSON.stringify({
          model: config.doubao.endpointId,
          messages: [
            {
              role: 'system',
              content: 'You are a nutrition analyst. Identify visible foods in the image and estimate total calories. Reply in simplified Chinese only. Return only a JSON object with keys foodName, estimatedCalories, and summary.'
            },
            {
              role: 'user',
              content: [
                {
                  type: 'text',
                  text: '\u8bf7\u8bc6\u522b\u56fe\u7247\u4e2d\u7684\u4e3b\u8981\u98df\u7269\uff0c\u5e76\u4f30\u7b97\u603b\u70ed\u91cf\u3002\u53ea\u8fd4\u56de JSON\uff0cestimatedCalories \u5fc5\u987b\u662f\u6570\u5b57\u3002'
                },
                {
                  type: 'image_url',
                  image_url: {
                    url: `data:${normalizedMimeType};base64,${base64Image}`
                  }
                }
              ]
            }
          ]
        })
      });

      const data = await response.json();
      if (!response.ok) {
        const errorMessage = parseDoubaoError(data, response.status);
        const upstreamCode = String(data?.code || data?.error?.code || '');
        if ((upstreamCode === '2300007' || response.status >= 500) && attempt < 2) {
          await wait(800 * (attempt + 1));
          continue;
        }
        throw new Error(errorMessage);
      }

      const rawReply = data?.choices?.[0]?.message?.content?.trim() || '';
      if (!rawReply) {
        throw new Error('\u8c46\u5305\u6ca1\u6709\u8fd4\u56de\u8bc6\u522b\u7ed3\u679c');
      }

      return parseFoodResult(rawReply);
    } catch (error) {
      lastError = error;
      if (attempt < 2) {
        await wait(800 * (attempt + 1));
        continue;
      }
    }
  }

  if (lastError instanceof Error) {
    return demoFoodResult(`豆包视觉调用失败：${lastError.message}`);
  }
  return demoFoodResult('豆包视觉识别失败');
}

module.exports = {
  analyzeFoodImage
};
