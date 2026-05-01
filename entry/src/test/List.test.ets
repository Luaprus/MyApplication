import localUnitTest from './LocalUnit.test';
import waterDisplayTest from './WaterDisplay.test';
import interactionActionsTest from './InteractionActions.test';
import authSessionPersistenceTest from './AuthSessionPersistence.test';
import featureInsightsTest from './FeatureInsights.test';
import recordInsightsTest from './RecordInsights.test';
import aiSuggestionsTest from './AiSuggestions.test';
import aiPromptBuildersTest from './AiPromptBuilders.test';
import aiConversationTest from './AiConversation.test';

export default function testsuite() {
  localUnitTest();
  waterDisplayTest();
  interactionActionsTest();
  authSessionPersistenceTest();
  featureInsightsTest();
  recordInsightsTest();
  aiSuggestionsTest();
  aiPromptBuildersTest();
  aiConversationTest();
}
