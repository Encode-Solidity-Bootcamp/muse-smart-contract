import { ethers } from "hardhat";
import { ETHNFTMarketplace__factory, TestSHIT__factory } from "../typechain-types";

async function main() {
    const [deployer,account1,account2] = await ethers.getSigners();


    // This is the contract for deploying the Marketplace
    const contractFactory = new ETHNFTMarketplace__factory(deployer);
    console.log("Deploying contract");
    const contract = await contractFactory.deploy();
    console.log("contract deployed");
    const contractTx = await contract.deployTransaction.wait();
    console.log(contractTx)

    //Deploy test token contract
    const tokenFactory = new TestSHIT__factory(deployer);
    console.log('Deploying contract')
    const tokenContract = await tokenFactory.deploy();
    const tokenContractTx = await tokenContract.deployTransaction.wait();
    console.log(tokenContractTx);

    //Mint Token 100 Tokens;
    const desAddress = deployer.address;
    const id = ethers.utils.parseEther("1");
    const mint_amount = ethers.utils.parseEther("100");
    const data = ethers.utils.parseBytes32String("sd")
    
    const minter = await tokenContract.mint(desAddress, id, mint_amount,data)
    const mintTx = await minter.wait();
    console.log(mintTx)


}


main().catch((error) =>{
    console.error(error);
    process.exitCode = 1;
});