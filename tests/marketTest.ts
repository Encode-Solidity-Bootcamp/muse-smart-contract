import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "hardhat";
import {expect, assert} from "chai";
import { deployContract } from "@nomiclabs/hardhat-ethers/types";

describe("MP", function () {

    async function deployMP() {
        
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();
    const fees = 10;
    const ONE_GWEI = 1_000_000_000;  
    
    
    // Mint to Owner's Address
    const toAddress = owner.address; ;
    const id = ethers.utils.parseEther("1");
    const mint_amount = ethers.utils.parseEther("1000");
    const data = "0x293232";
    

    const contractFactory = await ethers.getContractFactory("Marketplace");
    const contract = await contractFactory.deploy();
    const contractTx = await contract.deployTransaction.wait();
    const setPlatformFees = await contract.setFees( ethers.utils.parseEther(fees.toFixed(18) ));
    const setPlatformFeesTx = await setPlatformFees.wait();

    // Mint to otherAccount address
    const toAddress2 = owner.address; ;
    const id2 = ethers.utils.parseEther("1");
    const mint_amount2 = ethers.utils.parseEther("1000");
    const data2 = "0x293232";

    const setPlatformFees2 = await contract.setFees( ethers.utils.parseEther(fees.toFixed(18) ));
    const setPlatformFeesTx2 = await setPlatformFees2.wait();
    // console.log(setPlatformFeesTx2);

    return contractTx.contractAddress;
};

describe("Deployment", function () {
    it("fees should be equal to ", async function () {
        const contractAddress = await deployMP();
        const contract = await ethers.getContractAt("Marketplace", contractAddress);

        const fees = await contract.fees();
        expect(fees).to.equal(ethers.utils.parseEther("10"));
    });

    it("transaction should fail if called be non-owner", async function () {
        const [owner, otherAccount] = await ethers.getSigners();
        const contractAddress = await deployMP();
        const contract = await ethers.getContractAt("Marketplace", contractAddress);

        await expect(contract.connect(otherAccount).setFees(1)).to.be.revertedWith("Ownable: caller is not the owner");

    })
    
    it("check that correct amount is minted",async function () {
        const [owner, otherAccount] = await ethers.getSigners();
        const toAddress = owner.address; ;
        const id = ethers.utils.parseEther("1");
        const mint_amount = ethers.utils.parseEther("1000");
        const data = "0x293232";

        const contractFactory = await ethers.getContractFactory("TestSHIT")
        const contract = await contractFactory.deploy();
        const contractTx = await contract.deployTransaction.wait();
        const mint = await contract.mint(toAddress, id, mint_amount, data);
        const mintTx = await mint.wait();
        const bal = await contract.balanceOf(owner.address,id);
        

        await expect(bal).to.be.equal(ethers.utils.parseEther("1000"));
        
    })
})

});
