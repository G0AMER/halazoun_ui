'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

class SimpleWorkload extends WorkloadModuleBase {
    constructor() {
        super();
        this.contractID = 'SnailMarket'; // Smart contract name
    }

    /**
     * Initialize the workload module with parameters.
     */
    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext);

        this.userAddress = this.sutContext.ethereumAccounts[workerIndex].address;
        this.userPrivateKey = this.sutContext.ethereumAccounts[workerIndex].privateKey;
    }

    /**
     * Register a new user.
     */
    async registerUser() {
        const userName = `User_${this.workerIndex}`;
        const password = 'password123';
        const role = false; // Not an admin
        const referrer = '0x0000000000000000000000000000000000000000';

        const args = [userName, password, this.userAddress, this.userPrivateKey, referrer, role];

        const tx = {
            contractId: this.contractID,
            contractFunction: 'registerUser',
            contractArguments: args,
            readOnly: false,
        };

        await this.sutAdapter.sendRequests([tx]);
    }

    /**
     * Add a new snail to the market.
     */
    async addSnail() {
        const snailName = `Snail_${this.workerIndex}`;
        const price = 1000; // Price in wei
        const stock = 10;
        const category = 'Common';

        const args = [snailName, price, stock, category];

        const tx = {
            contractId: this.contractID,
            contractFunction: 'addSnail',
            contractArguments: args,
            readOnly: false,
        };

        await this.sutAdapter.sendRequests([tx]);
    }

    /**
     * Buy snails from the market.
     */
    async buySnails() {
        const snailId = 0; // Assuming we're buying the first snail
        const quantity = 1;

        const tx = {
            contractId: this.contractID,
            contractFunction: 'buySnails',
            contractArguments: [snailId, quantity],
            readOnly: false,
            invokerIdentity: this.userAddress,
            gasLimit: 1000000,
        };

        await this.sutAdapter.sendRequests([tx]);
    }

    /**
     * Get details of all snails.
     */
    async getAllSnails() {
        const tx = {
            contractId: this.contractID,
            contractFunction: 'getAllSnails',
            readOnly: true,
        };

        const result = await this.sutAdapter.sendRequests([tx]);
        console.log('Snails:', JSON.stringify(result));
    }

    /**
     * Submit transactions in this workload.
     */
    async submitTransaction() {
        // Simulate different operations
        const operation = Math.floor(Math.random() * 3);
        switch (operation) {
            case 0:
                await this.addSnail();
                break;
            case 1:
                await this.buySnails();
                break;
            case 2:
                await this.getAllSnails();
                break;
            default:
                console.log('Invalid operation.');
        }
    }

    /**
     * Clean up resources after the workload ends.
     */
    async cleanupWorkloadModule() {
        console.log('Cleaning up resources...');
    }
}

function createWorkloadModule() {
    return new SimpleWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;
