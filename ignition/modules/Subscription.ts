import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

export default buildModule('SubscriptionModule', (m) => {
  const subscription = m.contract('Subscription');

  return { subscription };
});
