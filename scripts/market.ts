import { Signer } from "ethers";
import { ethers } from "hardhat";
import { Marketplace__factory, TestSHIT__factory } from "../typechain-types";
import { marketplaceSol } from "../typechain-types/contracts";

async function main() {
    const [deployer,account1,account2] = await ethers.getSigners();


    // This is the contract for deploying the Marketplace
    const contractFactory = new Marketplace__factory(deployer);
    console.log("Deploying contract");
    const contract = await contractFactory.deploy();
    console.log("contract deployed");
    const contractTx = await contract.deployTransaction.wait();
    console.log("Marketplace Contract:",contractTx.contractAddress)

    //Deploy test token contract
    const tokenFactory = new TestSHIT__factory(deployer);
    console.log('Deploying contract')
    const tokenContract = await tokenFactory.deploy();
    const tokenContractTx = await tokenContract.deployTransaction.wait();
    console.log("testToken Contract:",tokenContractTx.contractAddress);

    //Mint Token 100 Tokens;
    const desAddress = deployer.address;
    const id = ethers.utils.parseEther("1");
    const mint_amount = ethers.utils.parseEther("1000");
    const data = "0x293232";
    
    const minter = await tokenContract.mint(desAddress, id, mint_amount,data)
    const mintTx = await minter.wait();
    console.log("ERC1155 NFT successfully minted");
    console.log("Hash of Token Minting",mintTx.blockHash);
    const owner = await tokenContract.owner();
    console.log("This is the owner", owner)
    console.log("This is the deployer", deployer.address)

    //Give Approval to Contract to safely transfer tokens
    const approval = await tokenContract.setApprovalForAll(contract.address, true);
    const approvalTx = await approval.wait();
    console.log("Approval successful");
    console.log("Token Approval Hash",approvalTx.blockHash);

    // pause marketplace.sol

    const pauseMP = await contract.connect(deployer).pauseMarketPlace();
    const pauseMPTx = await pauseMP.wait();
    console.log("MarketPlace successfully Paused with hash !:", pauseMPTx.blockHash)

    const checkMP = await contract.isPaused();
    if(checkMP){
        const resumeMP = await contract.connect(deployer).resumeMarketPlace();
        const resumeMPTx = await resumeMP.wait();
        console.log("MarketPlace successfully Resumed with hash !:", resumeMPTx.blockHash)
    }

    //add Tokens to Marketplace
    const price = 1;
    
    const listTokens = await contract.connect(deployer).addItem(tokenContract.address, ethers.utils.parseEther(price.toFixed(18)), 10, "baddest Team 11", 1 );
    const listTokensTx = await listTokens.wait();
    console.log("Token successfully added to marketplace")
    console.log("Add token BlockHash",listTokensTx.blockHash);

    //List Token listed in Marketplace

    const listedNFT = await contract.items(1);
    console.log("Token detail:", listedNFT.name);

    //Attempt to buy 
    const checkBalance = await account1.getBalance();
    console.log("account 1 Balance:",ethers.utils.formatEther(checkBalance));
    console.log("price of NFT", listedNFT.price);
    
    const amount = { value:ethers.BigNumber.from("1")};
    const tId = { value:ethers.BigNumber.from("1")};
    const buyNFT = await contract.connect(account1).buyItem(1,10, { value: ethers.utils.parseEther("100")});
    const buyNFTtx = await buyNFT.wait();
    const listedNFTt = await contract.items(1);
    console.log("Sold :",listedNFTt.sold);
    console.log("Buy Operation Successful")
    console.log("This is the txHash of purchase", buyNFTtx.blockHash)

    //retrieve the list of all items in the marketplace

    const count = await contract.itemCount();
    const countNumber = count.toNumber();
    const itemsArray = [];
    
    console.log(countNumber)
    for(let i = 1; i <= countNumber; i++ ){
        const retrieveList =await contract.items(i);
        console.log("The items should follow");
        itemsArray.push(retrieveList)
        console.log("End of loop")
    }
    console.log(itemsArray);
    




}


main().catch((error) =>{
    console.error(error);
    process.exitCode = 1;
});