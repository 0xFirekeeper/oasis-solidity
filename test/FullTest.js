const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("Deployment and Setup", function () {
    /*///////////////////////////////////////////////////////////////
                            DEPLOYMENT FIXTURE
    //////////////////////////////////////////////////////////////*/

    async function deployFixture() {
        const CrazyCamels = await ethers.getContractFactory("CrazyCamels");
        const EvolvedCamels = await ethers.getContractFactory("EvolvedCamels");
        const OasisFeatures = await ethers.getContractFactory("OasisFeatures");
        const OasisStakingToken = await ethers.getContractFactory("OasisStakingToken");
        const OasisGraveyard = await ethers.getContractFactory("OasisGraveyard");
        const OasisStake = await ethers.getContractFactory("OasisStake");
        const OasisToken = await ethers.getContractFactory("OasisToken");

        const [owner, addr1, addr2] = await ethers.getSigners();

        const crazyCamels = await CrazyCamels.deploy();
        const evolvedCamels = await EvolvedCamels.deploy();
        const oasisGraveyard = await OasisGraveyard.deploy();
        const oasisStakingToken = await OasisStakingToken.deploy();
        await crazyCamels.deployed();
        await evolvedCamels.deployed();
        await oasisGraveyard.deployed();
        await oasisStakingToken.deployed();

        const oasisToken = await OasisToken.deploy(oasisGraveyard.address);
        await oasisToken.deployed();

        const oasisStake = await OasisStake.deploy(
            evolvedCamels.address,
            oasisToken.address,
            oasisStakingToken.address
        );
        const oasisFeatures = await OasisFeatures.deploy(
            crazyCamels.address,
            evolvedCamels.address,
            oasisGraveyard.address,
            oasisToken.address
        );
        await oasisFeatures.deployed();
        await oasisStake.deployed();

        await oasisStakingToken.setOasisStake(oasisStake.address);

        await oasisToken.grantRole(
            ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER_ROLE")),
            oasisStake.address
        );

        await oasisToken.grantRole(
            ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER_ROLE")),
            oasisFeatures.address
        );

        await oasisToken.grantRole(
            ethers.utils.keccak256(ethers.utils.toUtf8Bytes("BURNER_ROLE")),
            oasisFeatures.address
        );

        await oasisToken.mint(oasisFeatures.address, ethers.utils.parseEther("500000000"));
        await oasisToken.mint(oasisStake.address, ethers.utils.parseEther("500000000"));
        await oasisStakingToken.mint(oasisStake.address, ethers.utils.parseEther("8888"));

        return {
            crazyCamels,
            evolvedCamels,
            oasisFeatures,
            oasisStakingToken,
            oasisGraveyard,
            oasisStake,
            oasisToken,
            owner,
            addr1,
            addr2,
        };
    }

    /*///////////////////////////////////////////////////////////////
                            DEPLOYMENT FUNCTION
    //////////////////////////////////////////////////////////////*/

    async function deploy(mintCamels = false, mintOST = false) {
        const {
            crazyCamels,
            evolvedCamels,
            oasisFeatures,
            oasisStakingToken,
            oasisGraveyard,
            oasisStake,
            oasisToken,
            owner,
            addr1,
            addr2,
        } = await loadFixture(deployFixture);

        if (mintCamels) {
            await crazyCamels.safeMint(owner.address, 10);
            await evolvedCamels.mint(owner.address, 10);
            expect(await crazyCamels.balanceOf(owner.address)).to.equal(10);
            expect(await evolvedCamels.balanceOf(owner.address)).to.equal(10);
        }

        if (mintOST) {
            await oasisToken.mint(owner.address, "1000000000000000000000000");
        }

        return {
            crazyCamels,
            evolvedCamels,
            oasisFeatures,
            oasisStakingToken,
            oasisGraveyard,
            oasisStake,
            oasisToken,
            owner,
            addr1,
            addr2,
        };
    }

    /*///////////////////////////////////////////////////////////////
                               DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    describe("Deploying", function () {
        it("Should deploy all contracts", async function () {
            const {} = await deploy();
        });

        it("Should deploy all contracts and mint test camels", async function () {
            const {} = await deploy(true);
        });

        it("Should deploy all contracts and mint OST", async function () {
            const {} = await deploy(false, true);
        });
    });

    /*///////////////////////////////////////////////////////////////
                               OASISFEATURES TESTS
    //////////////////////////////////////////////////////////////*/

    describe("OasisFeatures", function () {
        it("Should confirm oasisMint(10)", async function () {
            const {
                crazyCamels,
                evolvedCamels,
                oasisFeatures,
                oasisStakingToken,
                oasisGraveyard,
                oasisStake,
                oasisToken,
                owner,
                addr1,
                addr2,
            } = await deploy(false, false);

            await oasisFeatures.oasisMint(10);
            expect(await evolvedCamels.totalSupply()).to.equal(10);
            expect(await evolvedCamels.balanceOf(owner.address)).to.equal(10);
            expect(await oasisToken.balanceOf(owner.address)).to.equal(
                ethers.utils.parseEther("500000")
            );
        });

        it("Should confirm oasisBurn([1,2,3,4,5])", async function () {
            const {
                crazyCamels,
                evolvedCamels,
                oasisFeatures,
                oasisStakingToken,
                oasisGraveyard,
                oasisStake,
                oasisToken,
                owner,
                addr1,
                addr2,
            } = await deploy(true, false);

            await crazyCamels.setApprovalForAll(oasisFeatures.address, true);
            expect(
                await crazyCamels.isApprovedForAll(owner.address, oasisFeatures.address)
            ).to.equal(true);
            await oasisFeatures.oasisBurn([1, 2, 3, 4, 5]);
            expect(await crazyCamels.balanceOf(oasisGraveyard.address)).to.equal(5);
            expect(await crazyCamels.balanceOf(owner.address)).to.equal(5);
            expect(await oasisToken.balanceOf(owner.address)).to.equal(
                ethers.utils.parseEther("50000")
            );
        });

        it("Should confirm buyOST(100000)", async function () {
            const {
                crazyCamels,
                evolvedCamels,
                oasisFeatures,
                oasisStakingToken,
                oasisGraveyard,
                oasisStake,
                oasisToken,
                owner,
                addr1,
                addr2,
            } = await deploy(false, false);

            const quantity = 100000;
            const totalPrice = (await oasisFeatures.weiPricePerOst()) * quantity;
            await oasisFeatures.buyOST(quantity.toString(), {
                value: totalPrice.toString(),
            });
            expect(await oasisToken.balanceOf(owner.address)).to.equal(
                ethers.utils.parseEther("100000")
            );
        });

        it("Should confirm buyNFT(0)", async function () {
            const {
                crazyCamels,
                evolvedCamels,
                oasisFeatures,
                oasisStakingToken,
                oasisGraveyard,
                oasisStake,
                oasisToken,
                owner,
                addr1,
                addr2,
            } = await deploy(true, true);

            await evolvedCamels.setApprovalForAll(oasisFeatures.address, true);
            await oasisFeatures.depositNFT(
                evolvedCamels.address,
                1,
                ethers.utils.parseEther("100000")
            );

            await oasisToken.approve(oasisFeatures.address, ethers.utils.parseEther("100000"));
            await oasisFeatures.buyNFT(0);
            expect(await evolvedCamels.ownerOf(1)).to.equal(owner.address);
        });
    });

    /*///////////////////////////////////////////////////////////////
                               OASISSTAKING TESTS
    //////////////////////////////////////////////////////////////*/

    describe("OasisStake", function () {
        it("Should stake", async function () {
            const {
                crazyCamels,
                evolvedCamels,
                oasisFeatures,
                oasisStakingToken,
                oasisGraveyard,
                oasisStake,
                oasisToken,
                owner,
                addr1,
                addr2,
            } = await deploy(true, false);

            await evolvedCamels.setApprovalForAll(oasisStake.address, true);
            await oasisStake.stake([1, 2, 3, 4, 5]);
            expect(await evolvedCamels.ownerOf(3)).to.equal(oasisStake.address);
            expect(await oasisStakingToken.balanceOf(owner.address)).to.equal(
                ethers.utils.parseEther("5")
            );
        });

        it("Should claim rewards", async function () {
            const {
                crazyCamels,
                evolvedCamels,
                oasisFeatures,
                oasisStakingToken,
                oasisGraveyard,
                oasisStake,
                oasisToken,
                owner,
                addr1,
                addr2,
            } = await deploy(true, false);

            await evolvedCamels.setApprovalForAll(oasisStake.address, true);
            await oasisStake.stake([1, 2, 3, 4, 5]);
            expect(await evolvedCamels.ownerOf(3)).to.equal(oasisStake.address);
            expect(await oasisStakingToken.balanceOf(owner.address)).to.equal(
                ethers.utils.parseEther("5")
            );

            const balanceOST = await oasisToken.balanceOf(owner.address);
            await oasisStake.claimRewards();
            const newBalanceOST = await oasisToken.balanceOf(owner.address);
            expect(newBalanceOST).to.be.greaterThan(balanceOST);
        });

        it("Should unstake", async function () {
            const {
                crazyCamels,
                evolvedCamels,
                oasisFeatures,
                oasisStakingToken,
                oasisGraveyard,
                oasisStake,
                oasisToken,
                owner,
                addr1,
                addr2,
            } = await deploy(true, false);

            await evolvedCamels.setApprovalForAll(oasisStake.address, true);
            await oasisStake.stake([1, 2, 3, 4, 5]);
            expect(await evolvedCamels.ownerOf(3)).to.equal(oasisStake.address);
            expect(await oasisStakingToken.balanceOf(owner.address)).to.equal(
                ethers.utils.parseEther("5")
            );

            await oasisStakingToken.approve(oasisStake.address, ethers.utils.parseEther("5"));
            await oasisStake.unstake([1, 2, 3, 4, 5]);
            expect(await evolvedCamels.ownerOf(3)).to.equal(owner.address);
            expect(await oasisStakingToken.balanceOf(owner.address)).to.equal(0);
        });

        it("Should get token ids staked", async function () {
            const {
                crazyCamels,
                evolvedCamels,
                oasisFeatures,
                oasisStakingToken,
                oasisGraveyard,
                oasisStake,
                oasisToken,
                owner,
                addr1,
                addr2,
            } = await deploy(true, false);

            await evolvedCamels.setApprovalForAll(oasisStake.address, true);
            await oasisStake.stake([1, 2, 3, 4, 5]);
            expect(await evolvedCamels.ownerOf(3)).to.equal(oasisStake.address);
            expect(await oasisStakingToken.balanceOf(owner.address)).to.equal(
                ethers.utils.parseEther("5")
            );

            console.log(await oasisStake.getStakedTokens(owner.address));
        });
    });
});
