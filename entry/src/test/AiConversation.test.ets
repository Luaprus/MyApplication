import { describe, it, expect } from '@ohos/hypium';
import { ChatMessage } from '../main/ets/models/AppState';
import { buildDeepSeekMessages, createPendingAiQuestion, messagesForModel, PendingAiQuestion, replaceThinkingMessage } from '../main/ets/models/AiConversation';
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
