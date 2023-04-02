import { ethers } from "hardhat";
import {expect} from "chai";

describe("Lock", function () {

    async function deployMP() {
        
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();
    const fees = 0;
    const ONE_GWEI = 1_000_000_000;  
    
    
    
    const toAddress = owner.address; ;
    const id = ethers.utils.parseEther("1");
    const mint_amount = ethers.utils.parseEther("1000");
    const data = "0x293232";
    

    const contractFactory = await ethers.getContractFactory("Marketplace");
    const contract = await contractFactory.deploy();
    const contractTx = await contract.deployTransaction.wait();
    const setPlatformFees = await contract.setFees( ethers.utils.parseEther(fees.toFixed(18) ));
    const setPlatformFeesTx = await setPlatformFees.wait();

    return contractTx.contractAddress;
};
});
