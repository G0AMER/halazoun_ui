module.exports = {
    networks: {
        development: {
            host: "127.0.0.1",  // Localhost
            port: 8545,         // Default Ganache port
            network_id: "5777",    // Match any network id
        },
    },
    compilers: {
        solc: {
            version: "0.5.16",  // Make sure the Solidity version is compatible
        },
    },
};
