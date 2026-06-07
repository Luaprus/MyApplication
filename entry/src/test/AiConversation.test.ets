import { describe, it, expect } from '@ohos/hypium';
import { ChatMessage } from '../main/ets/models/AppState';
import { buildDeepSeekMessages, createPendingAiQuestion, messagesForModel, normalizeAssistantMessages, PendingAiQuestion, replaceThinkingMessage, sanitizeAssistantReply } from '../main/ets/models/AiConversation';
import { DeepSeekMessage } from '../main/ets/services/DeepSeekService';

export default function aiConversationTest() {
  describe('aiConversationTest', () => {
    it('messagesForModel should remove thinking placeholders', 0, () => {
      let stable: ChatMessage[] = messagesForModel(sampleHistory());

      expect(stable.length).assertEqual(2);
      expect(stable[0].content).assertEqual('\u4f60\u597d');
      expect(stable[1].content).assertEqual('\u6211\u60f3\u8bb0\u5f55\u996e\u6c34');
    });

    it('createPendingAiQuestion should append user and thinking messages', 0, () => {
      let pending: PendingAiQuestion = createPendingAiQuestion(sampleHistory(), '\u4eca\u5929\u600e\u4e48\u5403\uff1f', 100);

      expect(pending.stableMessages.length).assertEqual(2);
      expect(pending.userMessage.id).assertEqual(100);
      expect(pending.thinkingMessage.id).assertEqual(101);
      expect(pending.messages.length).assertEqual(4);
      expect(pending.messages[3].isThinking).assertTrue();
    });

    it('replaceThinkingMessage should replace placeholder or append fallback', 0, () => {
      let replaced: ChatMessage[] = replaceThinkingMessage(sampleHistory(), 3, '\u5efa\u8bae\u5c11\u6cb9\u5c11\u7cd6', 9);
      let fallback: ChatMessage[] = replaceThinkingMessage(messagesForModel(sampleHistory()), 99, '\u8865\u4e00\u6761\u56de\u590d', 10);

      expect(replaced.length).assertEqual(3);
      expect(replaced[2].id).assertEqual(9);
      expect(replaced[2].isThinking === true).assertFalse();
      expect(fallback.length).assertEqual(3);
      expect(fallback[2].content).assertEqual('\u8865\u4e00\u6761\u56de\u590d');
    });

    it('sanitizeAssistantReply should remove markdown heading and divider markers', 0, () => {
      let reply: string = sanitizeAssistantReply('---\n\n### \ud83c\udfaf \u4e0b\u5468\u76ee\u6807\n1. **\u6bcf\u65e5\u589e\u52a0 3000-5000 \u6b65**\uff1a\u53ef\u5206\u6563\u5728\u996d\u540e\u3002\n\n---\n\n\u5982\u679c\u4f60\u60f3\uff0c\u6211\u4e5f\u53ef\u4ee5\u8f6c\u4e3a\u63d0\u9192\u4efb\u52a1\u3002');

      expect(reply).assertEqual('\ud83c\udfaf \u4e0b\u5468\u76ee\u6807\n1. \u6bcf\u65e5\u589e\u52a0 3000-5000 \u6b65\uff1a\u53ef\u5206\u6563\u5728\u996d\u540e\u3002\n\n\u5982\u679c\u4f60\u60f3\uff0c\u6211\u4e5f\u53ef\u4ee5\u8f6c\u4e3a\u63d0\u9192\u4efb\u52a1\u3002');
    });

    it('normalizeAssistantMessages should clean restored assistant history only', 0, () => {
      let normalized: ChatMessage[] = normalizeAssistantMessages([
        {
          id: 1,
          role: 'assistant',
          content: '### \ud83d\udcca \u672c\u5468 AI \u5065\u5eb7\u5468\u62a5\n\n#### \u2705 \u505a\u5f97\u597d\u7684\u5730\u65b9\n- **\u996e\u98df\u63a7\u5236\u5230\u4f4d**\uff1a\u70ed\u91cf\u7a33\u5b9a\u3002'
        },
        {
          id: 2,
          role: 'user',
          content: '### \u7528\u6237\u81ea\u5df1\u8f93\u5165\u7684\u6587\u672c'
        }
      ]);

      expect(normalized[0].content).assertEqual('\ud83d\udcca \u672c\u5468 AI \u5065\u5eb7\u5468\u62a5\n\n\u2705 \u505a\u5f97\u597d\u7684\u5730\u65b9\n- \u996e\u98df\u63a7\u5236\u5230\u4f4d\uff1a\u70ed\u91cf\u7a33\u5b9a\u3002');
      expect(normalized[1].content).assertEqual('### \u7528\u6237\u81ea\u5df1\u8f93\u5165\u7684\u6587\u672c');
    });

    it('buildDeepSeekMessages should prepend system prompt and limit recent history', 0, () => {
      let history: ChatMessage[] = [];
      for (let index = 0; index < 10; index++) {
        history.push({
          id: index,
          role: index % 2 === 0 ? 'user' : 'assistant',
          content: `message-${index}`
        });
      }

      let messages: DeepSeekMessage[] = buildDeepSeekMessages('system prompt', history);

      expect(messages.length).assertEqual(9);
      expect(messages[0].role).assertEqual('system');
      expect(messages[1].content).assertEqual('message-2');
      expect(messages[8].content).assertEqual('message-9');
    });
  });
}

function sampleHistory(): ChatMessage[] {
  return [
    {
      id: 1,
      role: 'assistant',
      content: '\u4f60\u597d'
    },
    {
      id: 2,
      role: 'user',
      content: '\u6211\u60f3\u8bb0\u5f55\u996e\u6c34'
    },
    {
      id: 3,
      role: 'assistant',
      content: '\u601d\u8003\u4e2d...',
      isThinking: true
    }
  ];
}
