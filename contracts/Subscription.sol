// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

contract Subscription {

  address public owner;
  uint256 private nextServiceId = 1;
  uint256 private nextSubscriptionId = 1;
  uint256[] private allServiceIds;
  uint256[] private allSubscriptionIds;

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

  struct UserSubscription {
    bool active;
    uint32 startDate;
    uint32 nextPaymentDate;
    uint32 endDate;
  }

  mapping(uint256 => SubscriptionService) public allServices;
  mapping(address => uint256) public balances;
  mapping(address => mapping(uint256 => UserSubscription)) public userSubscriptions;
  mapping(address => uint256[]) public userSubscriptionIds;


  modifier verifyOwner(uint256 id) {
    require(id < nextServiceId && id > 0, "Service does not exist");
    require(allServices[id].serviceOwner == msg.sender, "Transaction denied. You are not the owner of this service");
    _;
  }

  modifier canSubscribe(uint256 serviceId) {
    SubscriptionService storage service = allServices[serviceId];
    require(serviceId < nextServiceId && serviceId > 0, "Service does not exist");
    require(!service.paused, "Service is paused");
    require(block.timestamp < service.endDate, "Service has expired");

    UserSubscription storage sub = userSubscriptions[msg.sender][serviceId];
    require(!sub.active, "Already subscribed");
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

  // **** Subrcibe functions ***** 
  function subscribeToService(uint256 serviceId, uint32 periods) public payable canSubscribe(serviceId) {
    SubscriptionService storage service = allServices[serviceId];
    UserSubscription storage sub = userSubscriptions[msg.sender][serviceId];

    uint256 totalPrice = service.price * periods;
    require(msg.value == totalPrice, "Incorrect payment amount");

    sub.active = true;
    sub.startDate = uint32(block.timestamp);
    sub.nextPaymentDate = uint32(block.timestamp) + service.cycleLength * 1 days;
    sub.endDate = sub.startDate + service.cycleLength * periods * 1 days;

    balances[service.serviceOwner] += msg.value;
    userSubscriptionIds[msg.sender].push(serviceId);
  }

  function getUserSubscriptions(address user) public view returns (UserSubscription[] memory) {
    uint256[] storage ids = userSubscriptionIds[user];
    UserSubscription[] memory subs = new UserSubscription[](ids.length);

    for (uint i = 0; i < ids.length; i++) {
      subs[i] = userSubscriptions[user][ids[i]];
    }

    return subs;
  }

  function getUserSubscriptionIds(address user) public view returns (uint256[] memory) {
    return userSubscriptionIds[user];
  }

  function getAllSubscriptionsEndDate(address user) public view returns (uint32[] memory) {
    uint256[] storage ids = userSubscriptionIds[user];
    uint32[] memory endDates = new uint32[](ids.length);

    for (uint i = 0; i < ids.length; i++) {
      endDates[i] = userSubscriptions[user][ids[i]].endDate;
    }

    return endDates;
  }


}