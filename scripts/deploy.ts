import { ethers, hardhatArguments } from "hardhat";
import * as Config from "./config";

import * as dotenv from 'dotenv' // see https://github.com/motdotla/dotenv#how-do-i-use-dotenv-with-import
dotenv.config()

async function main() {
  await Config.initConfig();
  const network = hardhatArguments.network ? hardhatArguments.network : "dev";
  const [deployer] = await ethers.getSigners();
  console.log("Deploying from address: ", deployer.address);

  const Resumiro = await ethers.getContractFactory("Resumiro");
  const resumiro = await Resumiro.deploy();
  await resumiro.deployed();

  console.log("Resumiro Contract address: ", resumiro.address);
  Config.setConfig(network + '.Resumiro', resumiro.address);

  await Config.updateConfig();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
