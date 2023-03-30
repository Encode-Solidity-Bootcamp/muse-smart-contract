import { providers } from "ethers";
import { ethers } from "hardhat";
import { ETHNFTMarketplace__factory } from "../typechain-types";

async function main() {
    const accounts = await ethers.getSigners();
    const signer = accounts[0]
    const contractFactory = new ETHNFTMarketplace__factory(signer);
    console.log("Deploying contract");
    const contract = await contractFactory.deploy();
    console.log("contract deployed");
    const contractTx = await contract.deployTransaction.wait();
    console.log(contractTx)


}


main().catch((error) =>{
    console.error(error);
    process.exitCode = 1;
});