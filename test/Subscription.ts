import { expect } from 'chai';
import { network } from 'hardhat';

const { ethers } = await network.connect();

describe('Subscription', () => {
  async function deploySubscriptionFixture() {
    const [owner, degen, chad] = await ethers.getSigners();

    const Subscription = await ethers.getContractFactory('Subscription');
    const subscription = await Subscription.deploy();

    return { subscription, owner, degen, chad };
  }

  describe('deployment', () => {
    it('should set the deployer as owner', async () => {
      const { subscription, owner } = await deploySubscriptionFixture();

      expect(await subscription.owner()).to.equal(owner.address);
    });
  });
});
