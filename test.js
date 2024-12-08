const {Web3} = require('web3');
const contractABI = require('./build/contracts/SnailMarket.json').abi;
const contractAddress = '0x4B0e1075C42A300567e69699A53950bD34EcE236'; // Replace with your deployed contract address

// Connect to Ganache or the Ethereum network (change to your RPC URL if not using Ganache)
const web3 = new Web3('http://localhost:8545'); // Or use a different RPC URL if deployed on another network

async function addSnails() {
    const accounts = await web3.eth.getAccounts();

    // The contract instance
    const snailMarket = new web3.eth.Contract(contractABI, contractAddress);

    // Add snails to the contract
    try {
        // Adding Snails (Name, Price in Wei, Stock)
        await snailMarket.methods.addSnail('Golden Snail', web3.utils.toWei('0.1', 'ether'), 100).send({ from: accounts[0] });
        await snailMarket.methods.addSnail('Silver Snail', web3.utils.toWei('0.05', 'ether'), 50).send({ from: accounts[0] });
        await snailMarket.methods.addSnail('Bronze Snail', web3.utils.toWei('0.02', 'ether'), 200).send({ from: accounts[0] });

        console.log('Snails have been added successfully!');
    } catch (error) {
        console.error('Error adding snails:', error);
    }
}

addSnails();
