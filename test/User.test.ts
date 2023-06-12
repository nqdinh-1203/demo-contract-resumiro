import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("User", function () {
    async function deployFixture() {
        const [deployer, candidate, recruiter, admin_company, admin] = await ethers.getSigners();

        const userFactory = await ethers.getContractFactory("User", deployer);
        const userContract = await userFactory.deploy();
        await userContract.deployed();

        const ADMIN_ROLE = await userContract.ADMIN_ROLE();
        const CANDIDATE_ROLE = await userContract.CANDIDATE_ROLE();
        const RECRUITER_ROLE = await userContract.RECRUITER_ROLE();
        const ADMIN_COMPANY_ROLE = await userContract.ADMIN_COMPANY_ROLE();

        return { userContract, deployer, candidate, recruiter, admin_company, admin, ADMIN_ROLE, CANDIDATE_ROLE, RECRUITER_ROLE, ADMIN_COMPANY_ROLE };
    }

    describe("Deployment", function () {
        it("Should set the right admin", async function () {
            const { userContract, deployer, ADMIN_ROLE } = await loadFixture(deployFixture);
            // console.log(ADMIN_ROLE);

            expect(await userContract.hasRole(deployer.address, ADMIN_ROLE)).to.equal(true);
        });
    });

    describe('Add user', () => {
        it("Should add user", async () => {
            const { userContract, candidate, recruiter, admin_company, CANDIDATE_ROLE, RECRUITER_ROLE, ADMIN_COMPANY_ROLE } = await loadFixture(deployFixture);

            await userContract.connect(candidate).addUser(candidate.address, 0);
            await userContract.connect(recruiter).addUser(recruiter.address, 1);
            await userContract.connect(admin_company).addUser(admin_company.address, 2);

            // console.log(await userContract.getAllUser());
            expect((await userContract.getAllUser()).length).to.equal(3);

            // console.log(await userContract.getAllCandidates());
            expect((await userContract.getAllCandidates()).length).to.equal(1);

            // check access control
            expect(await userContract.hasRole(candidate.address, CANDIDATE_ROLE)).to.equal(true);
            expect(await userContract.hasRole(recruiter.address, RECRUITER_ROLE)).to.equal(true);
            expect(await userContract.hasRole(admin_company.address, ADMIN_COMPANY_ROLE)).to.equal(true);
        });

        it("Should not add already user", async () => {
            const { userContract, candidate } = await loadFixture(deployFixture);

            await userContract.connect(candidate).addUser(candidate.address, 0);

            await expect(userContract.connect(candidate).addUser(candidate.address, 1)).to.revertedWithCustomError(userContract, "User__AlreadyExisted");
        })

        it("Should add admin", async () => {
            const { userContract, deployer, admin, ADMIN_ROLE } = await loadFixture(deployFixture);

            await userContract.connect(deployer).grantRole(admin.address, ADMIN_ROLE);

            expect(await userContract.hasRole(admin.address, ADMIN_ROLE)).to.equal(true);
        })

        it("Should not add user for not self", async () => {
            const { userContract, candidate, recruiter } = await loadFixture(deployFixture);

            await expect(userContract.connect(candidate).addUser(recruiter.address, 1)).to.revertedWithCustomError(userContract, "User__NotForSelf");
        })
    });

    describe('Remove user', () => {
        it("Should remove user", async () => {
            const { userContract, candidate, recruiter, CANDIDATE_ROLE } = await loadFixture(deployFixture);

            await userContract.connect(candidate).addUser(candidate.address, 0);
            await userContract.connect(recruiter).addUser(recruiter.address, 1);

            expect((await userContract.getAllUser()).length).to.equal(2);

            await userContract.deleteUser(candidate.address);

            expect((await userContract.getAllUser()).length).to.equal(1);
            expect(await userContract.isExisted(candidate.address)).to.equal(false);
            expect(await userContract.hasRole(candidate.address, CANDIDATE_ROLE)).to.equal(false);

            expect(await userContract.isExisted(recruiter.address)).to.equal(true);
        });

        it("Should not remove user that not exist", async () => {
            const { userContract, candidate } = await loadFixture(deployFixture);

            await expect(userContract.deleteUser(candidate.address)).to.be.revertedWithCustomError(userContract, "User__NotExisted");
        });

        it("Should not remove user for non-admin", async () => {
            const { userContract, candidate } = await loadFixture(deployFixture);

            await userContract.connect(candidate).addUser(candidate.address, 0);

            await expect(userContract.connect(candidate).deleteUser(candidate.address)).to.be.revertedWithCustomError(userContract, "User__NoRole");
        });
    })
});
