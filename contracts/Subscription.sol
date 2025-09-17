// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

contract Subscription {

  address public owner;
  uint256 private nextServiceId = 1;
  uint256[] private allServiceIds;

  struct SubscriptionService {
    address serviceOwner;
    string subscriptionName;
    uint128 price;
    uint32 startDate;
    uint32 endDate;
    uint32 cycleLength;
    uint256 id;
    bool paused;
  }

  struct Subscriptions {
    uint256 serviceId;
    address subscriber;
    uint32 startDate;
    uint32 nextPaymentDate;
    bool active;
  }

  mapping (uint256 => SubscriptionService) public allServices;
  mapping (uint256 => Subscriptions) public allSubscriptions;

  modifier verifyOwner(uint256 id) {
    require(allServices[id].serviceOwner == msg.sender, "Transaction denied. You are not the owner of this service");
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  function updateOwner(address newOwner) public {
    require(msg.sender == owner, "Only the currnet owner can update ownership");
    owner = newOwner;
  }

  function getAllServiceIds() public view returns (uint256[] memory) {
    return allServiceIds;
}

  function newSubscriptionService(
    string memory subscriptionName,
    uint128 price,
    uint32 endDate,
    uint32 cycleLength
  ) public {

    uint256 id = nextServiceId;

    allServices[id] = SubscriptionService({
      serviceOwner: msg.sender,
      subscriptionName: subscriptionName,
      price: price,
      startDate: uint32(block.timestamp),
      endDate: endDate,
      id: id,
      cycleLength: cycleLength,
      paused: false
    });

    allServiceIds.push(id);
    nextServiceId ++;
  }

  function updateServicePrice(uint256 id, uint128 newPrice) public verifyOwner(id) {
    allServices[id].price = newPrice;
  }

  function updateServicePause(uint256 id, bool pause) public verifyOwner(id) {
    allServices[id].paused = pause;
  }

  // Subrcibe functions
  function subscribeToService(uint256 id) public {

  }
}