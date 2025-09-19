// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

contract Subscription {
  address public owner;
  uint256 private nextServiceId = 1;
  uint256 private nextSubscriptionId = 1;
  uint256[] private allServiceIds;
  uint256[] private allSubscriptionIds;
  bool private _locked;

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
    _;
  }

  modifier notSubscribed(address user, uint256 serviceId) {
    require(!userSubscriptions[user][serviceId].active, "Already subscribed");
    _;
  }

  modifier hasActiveSubscription(address user, uint256 serviceId) {
    require(userSubscriptions[user][serviceId].active, "No active subscription");
    _;
  }

  modifier noReentrancy() {
    require(!_locked, "Stop making re-entrancy calls. I feel violated!");
    _locked = true;
    _;
    _locked = false;
  }

  event FundsWithdrawn(address indexed serviceOwner, uint256 amount);
  error NotServiceOwner(address caller, uint256 serviceId);
  error InsufficientBalance(uint256 available, uint256 requested);
  error AmountMustBeGreaterThanZero();
  error TransferFailed();

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

  function subscribeToService(uint256 serviceId, uint32 periods) 
    public 
    payable 
    canSubscribe(serviceId) 
    notSubscribed(msg.sender, serviceId)
  {
    SubscriptionService storage service = allServices[serviceId];

    uint256 totalPrice = service.price * periods;
    require(msg.value == totalPrice, "Incorrect payment amount");

    userSubscriptions[msg.sender][serviceId] = UserSubscription({
      active: true,
      startDate: uint32(block.timestamp),
      nextPaymentDate: uint32(block.timestamp) + service.cycleLength * 1 days,
      endDate: uint32(block.timestamp) + service.cycleLength * periods * 1 days
    });

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
    
    uint256 count = 0;
    for (uint i = 0; i < ids.length; i++) {
        uint256 serviceId = ids[i];
        if (!allServices[serviceId].paused) {
            count++;
        }
    }

    uint32[] memory endDates = new uint32[](count);

    uint256 index = 0;
    for (uint i = 0; i < ids.length; i++) {
        uint256 serviceId = ids[i];
        if (!allServices[serviceId].paused) {
            endDates[index] = userSubscriptions[user][serviceId].endDate;
            index++;
        }
    }

    return endDates;
}

  function handOverSubscription(address receiver, uint256 serviceId) 
    public 
    hasActiveSubscription(msg.sender, serviceId) 
    notSubscribed(receiver, serviceId)  
  {
    UserSubscription storage currentSub = userSubscriptions[msg.sender][serviceId];

    userSubscriptions[receiver][serviceId] = UserSubscription({
      active: currentSub.active,
      startDate: currentSub.startDate,
      nextPaymentDate: currentSub.nextPaymentDate,
      endDate: currentSub.endDate
    });

    delete userSubscriptions[msg.sender][serviceId];

    uint256[] storage senderIds = userSubscriptionIds[msg.sender];
    for (uint i = 0; i < senderIds.length; i++) {
      if (senderIds[i] == serviceId) {
          senderIds[i] = senderIds[senderIds.length - 1];
          senderIds.pop();
          assert(!userSubscriptions[msg.sender][serviceId].active); 

          break;
      }
    }

    userSubscriptionIds[receiver].push(serviceId);
  }

  function withdrawEarnings(uint256 serviceId, uint256 amount) public noReentrancy {
    if (allServices[serviceId].serviceOwner != msg.sender) {
        revert NotServiceOwner(msg.sender, serviceId);
    }

    uint256 balance = balances[msg.sender];

    if (balance < amount) {
        revert InsufficientBalance(balance, amount);
    }
    if (amount == 0) {
        revert AmountMustBeGreaterThanZero();
    }

    balances[msg.sender] -= amount;

    (bool ok, ) = payable(msg.sender).call{value: amount}("");
    if (!ok) {
        revert TransferFailed();
    }

    assert(balances[msg.sender] + amount >= amount);
    emit FundsWithdrawn(msg.sender, amount);
  }

  receive() external payable {
    revert("Random payments not allowed. Thank me later!");
  }

  fallback() external payable {
    revert("Function does not exist");
  }

}