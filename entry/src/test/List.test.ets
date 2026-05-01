import localUnitTest from './LocalUnit.test';
import waterDisplayTest from './WaterDisplay.test';
import interactionActionsTest from './InteractionActions.test';
import authSessionPersistenceTest from './AuthSessionPersistence.test';
import featureInsightsTest from './FeatureInsights.test';
import recordInsightsTest from './RecordInsights.test';

export default function testsuite() {
  localUnitTest();
  waterDisplayTest();
  interactionActionsTest();
  authSessionPersistenceTest();
  featureInsightsTest();
  recordInsightsTest();
}
