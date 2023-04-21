import { ethers, hardhatArguments } from "hardhat";
import * as Config from "./config";

import * as dotenv from 'dotenv' // see https://github.com/motdotla/dotenv#how-do-i-use-dotenv-with-import
dotenv.config()

async function main() {
  await Config.initConfig();
  const network = hardhatArguments.network ? hardhatArguments.network : "dev";
  const [deployer] = await ethers.getSigners();
  console.log("Deploying from address: ", deployer.address);

  // const User = await ethers.getContractFactory("User");
  // const user = await User.deploy();
  // await user.deployed();

  // console.log("User Contract address: ", user.address);
  // Config.setConfig(network + '.User', user.address);

  // const Company = await ethers.getContractFactory("Company");
  // const company = await Company.deploy("0x8ae8570C43C8774c73b3c9Fc0D21363FaE38b56D");
  // await company.deployed();

  // console.log("Company Contract address: ", company.address);
  // Config.setConfig(network + '.Company', company.address);

  const Certificate = await ethers.getContractFactory("Certificate");
  const certificate = await Certificate.deploy("0x8ae8570C43C8774c73b3c9Fc0D21363FaE38b56D");
  await certificate.deployed();

  console.log("Certificate Contract address: ", certificate.address);
  Config.setConfig(network + '.Certificate', certificate.address);

  await Config.updateConfig();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
