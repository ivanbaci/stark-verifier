import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';

const config: HardhatUserConfig = {
  solidity: '0.8.24',
  networks: {
    hardhat: {
      gas: 100000000000000000,
      blockGasLimit: 100000000000000000
    }
  }
};

export default config;
