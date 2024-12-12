'use strict';

module.exports.info = 'Basic transaction workload';

const contractID = 'YourContractName';
const contractFunction = 'YourFunctionName';

let bc, ctx;

module.exports.init = async function(blockchain, context, args) {
    bc = blockchain;
    ctx = context;
};

/*module.exports.run = async function() {
    const args = {
        arg1: 'value1',
        arg2: 'value2'
    };
    await bc.invokeSmartContract(ctx, contractID, contractFunction, args, 30);
};*/

module.exports.end = async function() {};
