import {ethers, Signer } from "ethers";
import {  } from "hardhat";
import { TestSHIT__factory } from "../typechain-types";
import { marketplaceSol } from "../typechain-types/contracts";
import * as dotenv from "dotenv";

dotenv.config();

async function main() {
    const marketplaceAddress = "0x23D30d4C0bd879C94008D6F0d159Ca72835fCF00";
    const tokenContract = "0x0fA257C0D33045Fa6Fdc7d7f29794AfDA29988F6";
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
    const Factory = new TestSHIT__factory();
    const connectFactory = await Factory.attach(tokenContract);
    console.log("attached successful")

    // const checkIsApprove = await connectFactory.connect(signer).isApprovedForAll(signer.address ,marketplaceAddress);
    // const checkTx = await checkIsApprove.valueOf();

    // console.log("try one", checkIsApprove);
    // console.log("try two",checkTx);

    const approve = await connectFactory.connect(signer).setApprovalForAll(marketplaceAddress, true);
    const approveTx = await approve.wait();

    console.log(approveTx.blockHash);
    console.log(approve.blockHash);
    console.log(approveTx.gasUsed);


}


main().catch((error) =>{
    console.error(error);
    process.exitCode = 1;
});