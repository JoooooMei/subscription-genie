import { expect } from 'chai';
import { network } from 'hardhat';
import { Subscription } from '../typechain-types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

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

  describe('Interaction', () => {
    let subscription: Subscription;
    let owner: SignerWithAddress;
    let degen: SignerWithAddress;
    let chad: SignerWithAddress;

    beforeEach(async () => {
      ({ subscription, owner, degen, chad } =
        await deploySubscriptionFixture());
    });

    describe('Create subscription service', () => {
      it('should set owner correctly', async () => {
        expect(await subscription.owner()).to.equal(owner.address);
      });

      it('should create a new subscription service and set all peramaters correctly', async () => {
        const price = 1000;
        const now = Math.floor(Date.now() / 1000);
        const endDate = Math.floor(Date.UTC(2080, 11, 31, 0, 0, 0) / 1000);

        await subscription.newSubscriptionService('Megaflix', price, endDate);

        const service = await subscription.allServices(1);

        expect(service.subscriptionName).to.equal('Megaflix');
        expect(service.price).to.equal(price);
        expect(service.serviceOwner).to.equal(owner.address);
        expect(service.startDate).to.be.closeTo(now, 10);
        expect(service.endDate).to.equal(endDate);
        expect(service.paused).to.equal(false);
      });
    });

    describe('Update ownership', () => {
      it('should set new address as contract owner', async () => {
        await subscription.updateOwner(degen.address);

        expect(await subscription.owner()).to.equal(degen.address);
      });
    });
  });
});
