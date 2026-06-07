import { ChatMessage } from './AppState';
import { DeepSeekMessage } from '../services/DeepSeekService';

export interface PendingAiQuestion {
  stableMessages: ChatMessage[];
  userMessage: ChatMessage;
  thinkingMessage: ChatMessage;
  messages: ChatMessage[];
}

export function messagesForModel(history: ChatMessage[]): ChatMessage[] {
  let nextHistory: ChatMessage[] = [];
  for (let index = 0; index < history.length; index++) {
    if (history[index].isThinking !== true) {
      nextHistory.push(history[index]);
    }
  }
  return nextHistory;
}

export function sanitizeAssistantReply(content: string): string {
  let cleanedLines: string[] = [];
  let lines: string[] = content.split('\n');

  for (let index = 0; index < lines.length; index++) {
    let line: string = lines[index].trim();
    if (/^(-{3,}|\*{3,}|_{3,})$/.test(line)) {
      continue;
    }

    line = line.replace(/^#{1,6}\s*/, '');
    line = line.replace(/\*\*/g, '');
    line = line.replace(/__/g, '');
    cleanedLines.push(line);
  }

  return cleanedLines.join('\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

export function normalizeAssistantMessages(history: ChatMessage[]): ChatMessage[] {
  let normalized: ChatMessage[] = [];
  for (let index = 0; index < history.length; index++) {
    let message: ChatMessage = history[index];
    if (message.role === 'assistant' && message.isThinking !== true) {
      normalized.push({
        id: message.id,
        role: message.role,
        content: sanitizeAssistantReply(message.content),
        isThinking: message.isThinking
      });
    } else {
      normalized.push(message);
    }
  }
  return normalized;
}

export function createPendingAiQuestion(history: ChatMessage[], content: string, requestId: number): PendingAiQuestion {
  let stableMessages: ChatMessage[] = messagesForModel(history);
  let userMessage: ChatMessage = {
    id: requestId,
    role: 'user',
    content: content
  };
  let thinkingMessage: ChatMessage = {
    id: requestId + 1,
    role: 'assistant',
    content: '\u601d\u8003\u4e2d...',
    isThinking: true
  };

  return {
    stableMessages: stableMessages,
    userMessage: userMessage,
    thinkingMessage: thinkingMessage,
    messages: [...stableMessages, userMessage, thinkingMessage]
  };
}

export function replaceThinkingMessage(history: ChatMessage[], thinkingId: number, content: string,
  assistantMessageId: number): ChatMessage[] {
  let nextMessages: ChatMessage[] = [];
  let replaced: boolean = false;

  for (let index = 0; index < history.length; index++) {
    let message: ChatMessage = history[index];
    if (!replaced && message.id === thinkingId) {
      nextMessages.push({
        id: assistantMessageId,
        role: 'assistant',
        content: sanitizeAssistantReply(content)
      });
      replaced = true;
    } else {
      nextMessages.push(message);
    }
  }

  if (!replaced) {
    nextMessages.push({
      id: assistantMessageId,
      role: 'assistant',
      content: sanitizeAssistantReply(content)
    });
  }

  return nextMessages;
}

export function buildDeepSeekMessages(systemPrompt: string, history: ChatMessage[]): DeepSeekMessage[] {
  let systemMessage: DeepSeekMessage = {
    role: 'system',
    content: systemPrompt
  };
  let conversation: DeepSeekMessage[] = [];
  history.slice(-8).forEach((message: ChatMessage) => {
    let mappedMessage: DeepSeekMessage = {
      role: message.role,
      content: message.content
    };
    conversation.push(mappedMessage);
  });
  return [systemMessage, ...conversation];
}
