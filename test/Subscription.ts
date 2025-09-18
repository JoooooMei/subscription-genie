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
        const cycleLength = 30;

        await subscription.newSubscriptionService(
          'Megaflix',
          price,
          endDate,
          cycleLength
        );

        const service = await subscription.allServices(1);

        expect(service.subscriptionName).to.equal('Megaflix');
        expect(service.price).to.equal(price);
        expect(service.serviceOwner).to.equal(owner.address);
        expect(service.startDate).to.be.closeTo(now, 10);
        expect(service.endDate).to.equal(endDate);
        expect(service.cycleLength).to.equal(cycleLength);
        expect(service.paused).to.equal(false);
      });
    });

    describe('Update ownership', () => {
      it('should set new address as contract owner', async () => {
        await subscription.updateOwner(degen.address);

        expect(await subscription.owner()).to.equal(degen.address);
      });
    });

    describe('Get alla service id:s', () => {
      it('should return an array of service Id:s', async () => {
        const price = 1000;
        const endDate = Math.floor(Date.UTC(2080, 11, 31, 0, 0, 0) / 1000);
        const cycleLength = 30;

        await subscription.newSubscriptionService(
          'Megaflix',
          price,
          endDate,
          cycleLength
        );
        await subscription.newSubscriptionService(
          'Megatix',
          price,
          endDate,
          cycleLength
        );

        const services = await subscription.getAllServiceIds();

        expect(services.map((id: number) => Number(id))).to.deep.equal([1, 2]);
      });
    });

    describe('Update subscription service', () => {
      it('should update the price for a subscription service', async () => {
        const price = 1000;
        const endDate = Math.floor(Date.UTC(2080, 11, 31, 0, 0, 0) / 1000);
        const cycleLength = 30;

        await subscription.newSubscriptionService(
          'Megaflix',
          price,
          endDate,
          cycleLength
        );

        await subscription.updateServicePrice(1, 2000);

        const service = await subscription.allServices(1);

        expect(service.price).to.equal(2000);
      });

      it('should pause the subscriptin service', async () => {
        const price = 1000;
        const endDate = Math.floor(Date.UTC(2080, 11, 31, 0, 0, 0) / 1000);
        const cycleLength = 30;

        await subscription.newSubscriptionService(
          'Megaflix',
          price,
          endDate,
          cycleLength
        );
        await subscription.updateServicePause(1, true);

        const service = await subscription.allServices(1);

        expect(service.paused).to.be.true;
      });
    });

    describe('Subscribe to a service', () => {
      beforeEach(async () => {
        const price = ethers.parseEther('0.01');
        const endDate = Math.floor(Date.UTC(2080, 11, 31, 0, 0, 0) / 1000);
        const cycleLength = 30;

        await subscription.newSubscriptionService(
          'Megaflix',
          price,
          endDate,
          cycleLength
        );
      });
      it('should allow a user to subscribe', async () => {
        const amont = ethers.parseEther('0.01');

        await subscription
          .connect(degen)
          .subscribeToService(1, { value: amont });

        const userSub = await subscription.userSubscriptions(degen.address, 1);
        expect(userSub.active).to.be.true;
      });

      it('should add serviceId to userSubscriptionIds', async () => {
        const amont = ethers.parseEther('0.01');

        await subscription
          .connect(degen)
          .subscribeToService(1, { value: amont });

        const userIds = await subscription.getUserSubscriptionIds(
          degen.address
        );
        expect(userIds.map((id: any) => Number(id))).to.include(1);
      });

      it('Should revert if wrong amount of eth is sent in payment', async () => {
        const wrongAmount = ethers.parseEther('0.05');

        await expect(
          subscription
            .connect(degen)
            .subscribeToService(1, { value: wrongAmount })
        ).to.be.revertedWith('Incorrect payment amount');
      });

      it('Should revert if user tries to subscribe to same service twice', async () => {
        const amont = ethers.parseEther('0.01');

        await subscription
          .connect(degen)
          .subscribeToService(1, { value: amont });

        await expect(
          subscription.connect(degen).subscribeToService(1, { value: amont })
        ).to.be.revertedWith('Already subscribed');
      });

      it('should add payed amount to service owners balance', async () => {
        const amont = ethers.parseEther('0.01');

        await subscription
          .connect(degen)
          .subscribeToService(1, { value: amont });

        const ownerBalance = await subscription.balances(owner.address);
        expect(ownerBalance).to.equal(amont);
      });

      it('should revert if service is paused', async () => {
        const amont = ethers.parseEther('0.01');

        await subscription
          .connect(degen)
          .subscribeToService(1, { value: amont });

        await subscription.updateServicePause(1, true);
        await expect(
          subscription.connect(degen).subscribeToService(1, { value: amont })
        ).to.be.revertedWith('Service is paused');
      });

      it('should set start date and next payment date correctly', async () => {
        const amount = ethers.parseEther('0.01');
        const now = Math.floor(Date.now() / 1000);

        await subscription
          .connect(degen)
          .subscribeToService(1, { value: amount });

        const userSub = await subscription.userSubscriptions(degen.address, 1);
        const cycleLength = 30;

        const startDate = Number(userSub.startDate);
        const nextPaymentDate = Number(userSub.nextPaymentDate);

        expect(Number(userSub.startDate)).to.be.closeTo(now, 50);
        expect(nextPaymentDate).to.equal(startDate + cycleLength * 24 * 3600);
      });

      describe('Get user subscriptions', () => {
        beforeEach(async () => {
          const price = ethers.parseEther('0.01');
          const endDate = Math.floor(Date.UTC(2080, 11, 31, 0, 0, 0) / 1000);
          const cycleLength = 30;

          await subscription.newSubscriptionService(
            'Megaflix',
            price,
            endDate,
            cycleLength
          );
          await subscription.newSubscriptionService(
            'Megatix',
            price,
            endDate,
            cycleLength
          );

          await subscription
            .connect(degen)
            .subscribeToService(1, { value: price });
        });

        it('should return all subscriptions for a user', async () => {
          const userSubs = await subscription.getUserSubscriptions(
            degen.address
          );

          expect(userSubs.length).to.equal(1);

          const sub = userSubs[0];
          expect(sub.active).to.be.true;
          expect(Number(sub.startDate)).to.be.gt(0);
          expect(Number(sub.nextPaymentDate)).to.be.gt(Number(sub.startDate));
        });

        it('should return an empty array if user has no subscriptions', async () => {
          const userSubs = await subscription.getUserSubscriptions(
            chad.address
          );
          expect(userSubs.length).to.equal(0);
        });
      });
    });
  });
});
