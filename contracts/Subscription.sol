// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

contract Subscription {

  address public owner;
  uint32 private nextId = 1;
  uint32[] private allServiceIds;

  struct SubscriptionService {
    address serviceOwner;
    string subscriptionName;
    uint128 price;
    uint32 startDate;
    uint32 endDate;
    uint32 id;
    uint32 cycleLength;
    bool paused;
  }

  struct Subscriber {
    address subscriber;
  }

  mapping (uint32 => SubscriptionService) public allServices;

  modifier verifyOwner(uint32 id) {
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

  function getAllServiceIds() public view returns (uint32[] memory) {
    return allServiceIds;
}

  function newSubscriptionService(
    string memory subscriptionName,
    uint128 price,
    uint32 endDate,
    uint32 cycleLength
  ) public {

    uint32 id = nextId;

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
    nextId ++;

  }

  function updateServicePrice(uint32 id, uint128 newPrice) public verifyOwner(id) {
    allServices[id].price = newPrice;
  }

  function updateServicePause(uint32 id, bool pause) public verifyOwner(id) {
    allServices[id].paused = pause;
  }
}