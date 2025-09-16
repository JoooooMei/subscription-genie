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
    uint32 duration;
    uint32 id;
    bool paused;
  }

  mapping (uint32 => SubscriptionService) public allServices;


  constructor() {
    owner = msg.sender;
  }

  function updateOwner(address newOwner) public {
    require(msg.sender == owner, "only the currnet owner can update ownership");
    owner = newOwner;
  }

  function getAllServiceIds() public view returns (uint32[] memory) {
    return allServiceIds;
}

  function newSubscriptionService(
    string memory subscriptionName,
    uint128 price,
    uint32 startDate,
    uint32 endDate,
    uint32 duration) public {

      uint32 id = nextId;

      allServices[id] = SubscriptionService({
        serviceOwner: msg.sender,
        subscriptionName: subscriptionName,
        price: price,
        startDate: startDate,
        endDate: endDate,
        duration: duration,
        id: id,
        paused: false
      });

      allServiceIds.push(id);
      nextId ++;

  }
}