const SnailMarket = artifacts.require("SnailMarket");
const web3 = require("web3");

contract("SnailMarket", (accounts) => {
    let contract;

    before(async () => {
        // Deploy the contract
        contract = await SnailMarket.deployed();
    });

    it("should add snails and retrieve their details", async () => {
        // Add snails
        await contract.addSnail("Garden Snail", web3.utils.toWei("0.001", "ether"), 50, "Garden");
        await contract.addSnail("African Snail", web3.utils.toWei("0.002", "ether"), 30, "Exotic");
        await contract.addSnail("Mystery Snail", web3.utils.toWei("0.0015", "ether"), 20, "Mystery");

        // Retrieve all snails
        const allSnails = await contract.getAllSnails();
        const ids = allSnails[0].map((id) => id.toString());
        const names = allSnails[1];
        const prices = allSnails[2].map((price) => web3.utils.fromWei(price.toString(), "ether"));
        const stocks = allSnails[3].map((stock) => stock.toString());

        // Assertions for each snail
        assert.equal(names[0], "Garden Snail");
        assert.equal(prices[0], "0.001");
        assert.equal(stocks[0], "50");

        assert.equal(names[1], "African Snail");
        assert.equal(prices[1], "0.002");
        assert.equal(stocks[1], "30");

        assert.equal(names[2], "Mystery Snail");
        assert.equal(prices[2], "0.0015");
        assert.equal(stocks[2], "20");

        console.log("Snails added successfully!");
    });

    it("should allow buying snails with correct ETH and update stock", async () => {
        // Buy 5 Garden Snails
        const initialBalance = await web3.eth.getBalance(contract.address);
        await contract.buySnails(0, 5, { from: accounts[1], value: web3.utils.toWei("0.005", "ether") });

        // Check updated details
        const snail = await contract.getSnailDetails(0);
        assert.equal(snail[2].toString(), "45"); // Stock should be reduced to 45

        // Check contract balance
        const newBalance = await web3.eth.getBalance(contract.address);
        assert.equal(
            web3.utils.fromWei(newBalance, "ether"),
            (parseFloat(web3.utils.fromWei(initialBalance, "ether")) + 0.005).toString()
        );

        console.log("Snail bought successfully, stock updated!");
    });

    it("should revert if trying to buy more snails than available", async () => {
        try {
            await contract.buySnails(1, 40, {
                from: accounts[2],
                value: web3.utils.toWei("0.08", "ether"),
            });
            assert.fail("Expected transaction to revert");
        } catch (error) {
            assert.include(error.message, "Insufficient stock");
            console.log("Transaction reverted as expected due to insufficient stock.");
        }
    });

    it("should revert if incorrect ETH is sent for a purchase", async () => {
        try {
            await contract.buySnails(2, 5, {
                from: accounts[3],
                value: web3.utils.toWei("0.005", "ether"), // Incorrect amount
            });
            assert.fail("Expected transaction to revert");
        } catch (error) {
            assert.include(error.message, "Incorrect ETH sent");
            console.log("Transaction reverted as expected due to incorrect ETH.");
        }
    });

    it("should allow the owner to withdraw funds", async () => {
        // Owner withdraws funds
        const ownerBalanceBefore = await web3.eth.getBalance(accounts[0]);
        await contract.withdrawFunds({ from: accounts[0] });
        const ownerBalanceAfter = await web3.eth.getBalance(accounts[0]);
        const contractBalance = await web3.eth.getBalance(contract.address);

        // Assertions
        assert.equal(contractBalance, "0", "Contract balance should be zero after withdrawal");
        assert(
            parseFloat(web3.utils.fromWei(ownerBalanceAfter, "ether")) >
            parseFloat(web3.utils.fromWei(ownerBalanceBefore, "ether")),
            "Owner's balance should increase after withdrawal"
        );

        console.log("Funds withdrawn successfully!");
    });
});
