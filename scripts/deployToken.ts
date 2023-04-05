import {ethers, Signer } from "ethers";
import {  } from "hardhat";
import { Marketplace__factory, TestSHIT__factory } from "../typechain-types";
import { marketplaceSol } from "../typechain-types/contracts";
import * as dotenv from "dotenv";

dotenv.config();

async function main() {
    const marketplaceAddress = "0x723aBE8635805F3E3673362F09e1cE62b8EfD20E";
    const provider = new ethers.providers.InfuraProvider(
        "sepolia",
        process.env.INFURA_API_KEY
        );
    const privateKey = process.env.PRIVATE_KEY;
    if(!privateKey || privateKey.length <= 0)
        throw new Error("Missing private key");
    const wallet = new ethers.Wallet(privateKey);
    const signer = wallet.connect(provider);
    const balance = await signer.getBalance();
    console.log(`Wallet balance: ${balance} Wei`);

    // Set up MarketplaceV2 contract factory
    const Factory = new TestSHIT__factory(signer);

    // Deploy the contract
    const contract = await Factory.deploy();

    // Wait for the contract to be mined
    const contractTx = await contract.deployTransaction.wait();

    // Log contract address and transaction hash
    console.log('Contract deployed to:', contract.address);
    console.log('Transaction hash:', contract.deployTransaction.hash);
    console.log('Transaction hash:', contractTx.blockHash);


    //Mint Token 100 Tokens;
    
    const toAddress = "0x416b2a7930a9c25aeceb897ccb62f057712a3b6e";
    const id = 1;
    const mint_amount = 1000;
    const data = "0x293232";
    
    const minter = await contract.mint(toAddress, id, mint_amount,data)
    const mintTx = await minter.wait();
    console.log("ERC1155 NFT successfully minted");
    console.log("Hash of Token Minting",mintTx.blockHash);
    const owner = await contract.owner();
    console.log("This is the owner", owner)
    

    //Give Approval to Contract to safely transfer tokens
    const approval = await contract.setApprovalForAll(marketplaceAddress, true);
    const approvalTx = await approval.wait();
    console.log("Approval successful");
    console.log("Token Approval Hash",approvalTx.blockHash);

    console.log(`Wallet balance: ${balance} Wei`);

}


main().catch((error) =>{
    console.error(error);
    process.exitCode = 1;
});