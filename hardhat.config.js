import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";

/** @type import('hardhat/config').HardhatUserConfig */

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const OPTIMISM_RPC_URL = process.env.OPTIMISM_RPC_URL;
const OMEN_TEST_PRIVATE_KEY = process.env.OMEN_TEST_PRIVATE_KEY;
const OPTIMISTIC_ETHERSCAN_API_KEY = process.env.OPTIMISTIC_ETHERSCAN_API_KEY;

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    //run yarn hardhat node --> to spin up a node in terminal that persists
    //run yarn hardhat run scripts/deploy.js --network localhost --> to run scripts on localhost
    localhost: {
      url: "http://127.0.0.1:8545/",
      chainId: 31337,
    },
  },
  solidity: {
    compilers: [
      { version: "0.8.20" },
      { version: "0.6.8", settings: {} },
      { version: "0.7.6", settings: {} },
    ],
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },

  optimisticEtherscan: {
    apiKey: OPTIMISTIC_ETHERSCAN_API_KEY,
  },
};
