import { ChatMessage } from './AppState';

export interface SuggestionItem {
  id: number;
  label: string;
  tint: string;
  bgColor: string;
}

export interface ProfileMenuItem {
  id: number;
  title: string;
  subtitle: string;
  glyph: string;
  tint: string;
  bgColor: string;
  badge: string;
}

export interface AiModuleModel {
  messages: ChatMessage[];
  suggestions: SuggestionItem[];
  isRequesting: boolean;
}
