/**
 * AI Service Interface for Health Management App
 * 
 * You can replace the mock implementation with a real API call (e.g., OpenAI, Claude, or your own backend).
 */

export interface ChatResponse {
  message: string;
  status: 'success' | 'error';
  suggestions?: string[];
}

export const aiService = {
  /**
   * Sends a message to the AI and gets a response
   * @param query The user's question or command
   * @returns Promise<ChatResponse>
   */
  async chat(query: string): Promise<ChatResponse> {
    // Replace "YOUR_API_KEY_HERE" and the URL below with your actual backend/AI service configuration
    const API_URL = "https://api.example.com/v1/health-assistant";
    const API_KEY = "YOUR_API_KEY_HERE";

    console.log(`[AI Interface] Calling ${API_URL} with query: "${query}"`);

    // --- MOCK IMPLEMENTATION ---
    // Simulating network latency
    await new Promise(resolve => setTimeout(resolve, 1500));

    // Simple keyword-based mock logic
    const lowerQuery = query.toLowerCase();
    
    if (lowerQuery.includes("水") || lowerQuery.includes("喝")) {
      return {
        message: "建议每天保持 2000ml 以上的饮水量。你目前完成了 1/4，继续加油！充足的水分可以加速脂肪代谢。",
        status: 'success',
        suggestions: ["再喝 250ml", "查看喝水提醒设置"]
      };
    }

    if (lowerQuery.includes("重") || lowerQuery.includes("胖")) {
      return {
        message: "体重波动是正常的。建议在每天早晨空腹称重，这样数据更准确。你的减重趋势很健康！",
        status: 'success',
        suggestions: ["查看历史曲线", "分析饮食结构"]
      };
    }

    if (lowerQuery.includes("运动") || lowerQuery.includes("累")) {
      return {
        message: "如果感到疲劳，可以尝试拉伸或散步等低强度运动。保持节奏比追求高强度更重要。",
        status: 'success',
        suggestions: ["开始冥想", "查看今日步数"]
      };
    }

    return {
      message: `收到你的消息：“${query}”。作为你的健康管家，我建议你保持规律作息。有什么具体的健康问题我可以帮到你吗？`,
      status: 'success'
    };
    // --- END MOCK IMPLEMENTATION ---

    /* 
    // REAL IMPLEMENTATION EXAMPLE:
    try {
      const response = await fetch(API_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${API_KEY}`
        },
        body: JSON.stringify({ message: query })
      });
      const data = await response.json();
      return {
        message: data.choices[0].message.content,
        status: 'success'
      };
    } catch (error) {
      console.error("AI API Error:", error);
      return {
        message: "抱歉，我现在处理信息时遇到了点困难，请稍后再试。",
        status: 'error'
      };
    }
    */
  }
};
