import {ethers, Signer } from "ethers";
import {  } from "hardhat";
import { Marketplace__factory, TestSHIT__factory } from "../typechain-types";
import { marketplaceSol } from "../typechain-types/contracts";
import * as dotenv from "dotenv";

dotenv.config();

async function main() {
    const tokenContract = "0x0fA257C0D33045Fa6Fdc7d7f29794AfDA29988F6";
    // const marketplaceAddress = "0x723aBE8635805F3E3673362F09e1cE62b8EfD20E";
    const marketplaceAddress = "0x23D30d4C0bd879C94008D6F0d159Ca72835fCF00";
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

    // Set up Marketplace contract factory
    const mpContract = new Marketplace__factory(signer);
    const contractX = await mpContract.attach(marketplaceAddress)
    console.log("Marketplace attached")
   

    //add Tokens to Marketplace
    const price = ethers.utils.parseEther("0.000000001");
    const idListToken = 1;
    const amountToken = 10;
    const dataBytes = "Unit";

    console.log("adding tokens");
    const listTokens = await contractX.connect(signer).addItem(tokenContract,idListToken, amountToken, price, dataBytes);   
    const listTokensTx = await listTokens.wait();
    console.log("Token successfully added to marketplace")
    console.log("Add token BlockHash",listTokensTx.blockHash);
    console.log("total gas used:",listTokensTx.gasUsed)

    // List Token listed in Marketplace

    const listedNFT = await contractX.items(2);
    console.log("Token detail from hard code:", listedNFT.name);

    //Attempt to buy 
    const checkBalance = await signer.getBalance();
    console.log("account 1 Balance:",ethers.utils.formatEther(checkBalance));
    console.log("price of hard coded NFT", listedNFT.price);
    
    const a1 =await signer.getBalance();
    console.log( "this is the balance of a1:",a1)
    const amount = { value:ethers.BigNumber.from("1")};
    const tId = { value:ethers.BigNumber.from("1")};
    const buyNFT = await contractX.connect(signer).buyItem(idListToken,1, { value: price.mul(2)});
    const buyNFTtx = await buyNFT.wait();
    const listedNFTt = await contractX.items(idListToken);
    console.log("Sold :",listedNFTt.sold);
    console.log("Buy Operation Successful")
    console.log("This is the txHash of purchase", buyNFTtx.blockHash)

  
    const itemsArray = [];
    // console.log("This is the txHash of purchase", buyNFTtx.blockHash)
    const count = await contractX.itemCount();
    const countNumber = count.toNumber();
    console.log("Total Item in the list:",countNumber)
    for(let i = 1; i <= countNumber; i++ ){
        const retrieveList =await contractX.items(i);
        // console.log("The items should follow");
        itemsArray.push(retrieveList)
        // console.log("End of loop")

        const Ay = await contractX.isItemUnlisted(i);
        console.log("Unlisted",Ay);
        const xy = await contractX.setFees(1)
        const xyTx = await xy.wait();
    }
    console.log(itemsArray);
}


main().catch((error) =>{
    console.error(error);
    process.exitCode = 1;
});