// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;


contract SnailMarket {
    struct Snail {
        uint256 id;
        string name;
        uint256 price; // Price in wei
        uint256 stock;
        string category;
        uint256 totalRatings;
        uint256 numRatings;
    }

    struct User {
        uint256 userId; // Incremental user ID
        address userAddress;
        string name;
        bytes32 passwordHash; // Store hashed password
        bool isAdmin;
        uint256 referralReward;
        uint256[] orderHistory;
        uint256[] favoriteSnails;
    }

    struct Order {
        uint256 orderId;
        uint256 snailId;
        uint256 quantity;
        uint256 totalPrice;
        uint256 timestamp;
    }

    event SnailAdded(uint256 indexed id, string name, uint256 price, uint256 stock, string category);
    event SnailUpdated(uint256 indexed id, string name, uint256 price, uint256 stock, string category);
    event SnailDeleted(uint256 indexed id);
    event Transaction(
        uint256 indexed snailId,
        address indexed buyer,
        uint256 quantity,
        uint256 totalPrice,
        uint256 timestamp
    );
    event MarketPaused(bool isPaused);
    event RatingAdded(uint256 indexed snailId, address indexed user, uint256 rating);
    event ReferralRewardClaimed(address indexed user, uint256 reward);

    address payable public owner;
    bool public isPaused = false;

    uint256 public nextSnailId = 0;
    uint256 public nextOrderId = 0;

    mapping(uint256 => Snail) private snails;
    mapping(address => User) private users;
    mapping(uint256 => Order) private orders;
    mapping(uint256 => address) private userIdToAddress; // Map user IDs to addresses
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyAdmin() {
        require(users[msg.sender].isAdmin || msg.sender == owner, "Only admin can perform this action");
        _;
    }

    modifier onlyRegistered() {
        require(bytes(users[msg.sender].name).length > 0, "User not registered");
        _;
    }

    modifier marketActive() {
        require(!isPaused, "Market is paused");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function toggleMarketPause() public onlyOwner {
        isPaused = !isPaused;
        emit MarketPaused(isPaused);
    }
    uint256 private nextUserId = 0; // Start from 0 for better readability
    function authenticateUser(string memory name, string memory password) public view returns (bool) {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(password).length > 0, "Password cannot be empty");

        bytes32 passwordHash = keccak256(abi.encodePacked(password));
        bool userFound = false;

        for (uint256 i = 0; i < nextUserId; i++) {
            address userAddress = userIdToAddress[i];
            User storage user = users[userAddress];

            if (keccak256(abi.encodePacked(user.name)) == keccak256(abi.encodePacked(name))) {
                userFound = true;
                require(user.passwordHash == passwordHash, "Incorrect password");
                return true; // User authenticated successfully
            }
        }

        require(userFound, "User not registered");
        return false; // Default return if user not found
    }




    function registerUser(
        string memory name,
        string memory password,
        address userAddress,
        address referrer
    ) public {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(users[msg.sender].name).length == 0, "User already registered");
        require(bytes(password).length > 0, "Password cannot be empty");

        uint256[] memory orderHistory;
        uint256[] memory favoriteSnails;

        users[msg.sender] = User({
            userId: nextUserId,
            userAddress: userAddress,
            name: name,
            passwordHash: keccak256(abi.encodePacked(password)),
            isAdmin: false,
            referralReward: 0,
            orderHistory: orderHistory,
            favoriteSnails: favoriteSnails
        });

        userIdToAddress[nextUserId] = msg.sender; // Map the new user ID to the address
        nextUserId++; // Increment the user ID counter

        if (referrer != address(0) && referrer != msg.sender && bytes(users[referrer].name).length > 0) {
            users[referrer].referralReward += 1 ether;
        }
    }

    function getUserById(uint256 userId) public view returns (string memory name, address userAddress) {
        require(userId > 0 && userId < nextUserId, "Invalid user ID");
        address addr = userIdToAddress[userId];
        User storage user = users[addr];
        return (user.name, user.userAddress);
    }


    function addSnail(string memory name, uint256 price, uint256 stock, string memory category) public onlyAdmin {
        require(bytes(name).length > 0, "Snail name cannot be empty");
        require(price > 0, "Price must be greater than zero");
        require(stock > 0, "Stock must be greater than zero");
        require(bytes(category).length > 0, "Category cannot be empty");

        snails[nextSnailId] = Snail(nextSnailId, name, price, stock, category, 0, 0);
        emit SnailAdded(nextSnailId, name, price, stock, category);
        nextSnailId++;
    }

    function updateSnail(
        uint256 snailId,
        string memory name,
        uint256 price,
        uint256 stock,
        string memory category
    ) public onlyAdmin {
        Snail storage snail = snails[snailId];
        require(snail.id == snailId, "Snail does not exist");

        snail.name = name;
        snail.price = price;
        snail.stock = stock;
        snail.category = category;

        emit SnailUpdated(snailId, name, price, stock, category);
    }

    function deleteSnail(uint256 snailId) public onlyAdmin {
        require(snails[snailId].id == snailId, "Snail does not exist");
        delete snails[snailId];
        emit SnailDeleted(snailId);
    }

    function buySnails(uint256 snailId, uint256 quantity) public payable onlyRegistered marketActive {
        require(quantity > 0, "Quantity must be greater than zero");

        Snail storage snail = snails[snailId];
        require(snail.id == snailId, "Snail does not exist");
        require(quantity <= snail.stock, "Insufficient stock");

        uint256 totalCost = snail.price * quantity;
        require(msg.value == totalCost, "Incorrect ETH sent");

        snail.stock -= quantity;

        orders[nextOrderId] = Order(nextOrderId, snailId, quantity, totalCost, block.timestamp);
        users[msg.sender].orderHistory.push(nextOrderId);
        nextOrderId++;

        emit Transaction(snailId, msg.sender, quantity, totalCost, block.timestamp);
    }

    function rateSnail(uint256 snailId, uint256 rating) public onlyRegistered {
        require(snailId < nextSnailId, "Snail does not exist");
        require(rating > 0 && rating <= 5, "Rating must be between 1 and 5");

        Snail storage snail = snails[snailId];
        snail.totalRatings += rating;
        snail.numRatings++;

        emit RatingAdded(snailId, msg.sender, rating);
    }

    function addFavoriteSnail(uint256 snailId) public onlyRegistered {
        require(snailId < nextSnailId, "Snail does not exist");
        users[msg.sender].favoriteSnails.push(snailId);
    }

    function claimReferralReward() public onlyRegistered {
        uint256 reward = users[msg.sender].referralReward;
        require(reward > 0, "No rewards available");

        users[msg.sender].referralReward = 0;
        msg.sender.transfer(reward);

        emit ReferralRewardClaimed(msg.sender, reward);
    }

    function getAllSnails()
    public
    view
    returns (uint256[] memory ids, string[] memory names, uint256[] memory prices, uint256[] memory stocks)
    {
        ids = new uint256[](nextSnailId);
        names = new string[](nextSnailId);
        prices = new uint256[](nextSnailId);
        stocks = new uint256[](nextSnailId);

        for (uint256 i = 0; i < nextSnailId; i++) {
            Snail storage snail = snails[i];
            ids[i] = snail.id;
            names[i] = snail.name;
            prices[i] = snail.price;
            stocks[i] = snail.stock;
        }

        return (ids, names, prices, stocks);
    }


    function getAverageRating(uint256 snailId) public view returns (uint256) {
        Snail storage snail = snails[snailId];
        if (snail.numRatings == 0) return 0;
        return snail.totalRatings / snail.numRatings;
    }

    function getUserDetails(address userAddress)
    public
    view
    returns (
        string memory name,
        bool isAdmin,
        uint256 referralReward,
        uint256[] memory orderHistory,
        uint256[] memory favoriteSnails
    )
    {
        User storage user = users[userAddress];
        require(bytes(user.name).length > 0, "User does not exist");
        return (user.name, user.isAdmin, user.referralReward, user.orderHistory, user.favoriteSnails);
    }

    function getSnailDetails(uint256 snailId)
    public
    view
    returns (
        string memory name,
        uint256 price,
        uint256 stock,
        string memory category
    )
    {
        Snail storage snail = snails[snailId];
        require(snail.id == snailId, "Snail does not exist");
        return (snail.name, snail.price, snail.stock, snail.category);
    }
}
