import { ethers } from "hardhat";
import { Contract, Signer } from "ethers";
import { expect } from "chai";

describe("NFTMarketplace", function () {
  let nftMarketplace: Contract;
  let erc1155: Contract;
  let owner: Signer;
  let seller: Signer;
  let buyer: Signer;

  beforeEach(async function () {
    // Deploy the NFTMarketplace contract
    const NFTMarketplace = await ethers.getContractFactory("ETHNFTMarketplace");
    nftMarketplace = await NFTMarketplace.deploy();
    await nftMarketplace.deployed();

    // Deploy an ERC1155 token contract to use for testing
    const ERC1155 = await ethers.getContractFactory("ERC1155Mock");
    erc1155 = await ERC1155.deploy();
    await erc1155.deployed();

    // Get signers
    [owner, seller, buyer] = await ethers.getSigners();
  });

  it("should add a new item to the marketplace", async function () {
    const tokenId = 1;
    const amount = 1;
    const name = "Test Item";
    const price = ethers.utils.parseEther("1");

    // Add a new item to the marketplace
    await erc1155.connect(seller).mint(seller.getAddress(), tokenId, amount, []);
    await erc1155.connect(seller).setApprovalForAll(nftMarketplace.address, true);
    await nftMarketplace.connect(seller).addItem(erc1155.address, tokenId, amount, name, price);

    // Check that the item was added correctly
    const item = await nftMarketplace.items(1);
    expect(item.nftContract).to.equal(erc1155.address);
    expect(item.tokenId).to.equal(tokenId);
    expect(item.amount).to.equal(amount);
    expect(item.name).to.equal(name);
    expect(item.price).to.equal(price);
    expect(item.seller).to.equal(await seller.getAddress());
    expect(item.sold).to.equal(false);
  });

  it("should not allow non-owners to add an item to the marketplace", async function () {
    const tokenId = 1;
    const amount = 1;
    const name = "Test Item";
    const price = ethers.utils.parseEther("1");

    // Try to add a new item to the marketplace as a non-owner
    await expect(
      nftMarketplace.connect(buyer).addItem(erc1155.address, tokenId, amount, name, price)
    ).to.be.revertedWith("Only token owner can list for sale");
  });

  it("should not allow buying an item that does not exist", async function () {
    const itemId = 1;

    // Try to buy an item that does not exist
    await expect(nftMarketplace.connect(buyer).buyItem(itemId, 1)).to.be.revertedWith("Item does not exist");
  });

  it("should not allow buying an already sold item", async function () {
    const tokenId = 1;
    const amount = 1;
    const name = "Test Item";
    const price = ethers.utils.parseEther("1");
});

  })

    // Add a new item to the marketplace
    // await erc1155.connect(seller).mint(seller.getAddress(), tokenId, amount, []);
    // await erc1155.connect(seller).setApprovalForAll(nftMarketplace.address, true);
    // await nftMarketplace.connect(seller).addItem(erc1155.address,
