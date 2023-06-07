import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";

// type CompanyProps = {
//     id?: number,
//     name?: string,
//     website?: string,
//     location?: string,
//     address?: string
// }

// const companyData = {
//     fpt: {
//         name: 
//     }
// }

describe("Company", function () {
    async function deployFixture() {
        const [deployer, candidate, recruiter, admin, admin2] = await ethers.getSigners();

        const userFactory = await ethers.getContractFactory("User", deployer);
        const userContract = await userFactory.deploy();
        await userContract.deployed();

        const companyFactory = await ethers.getContractFactory("Company", deployer);
        const companyContract = await companyFactory.deploy(userContract.address);
        await companyContract.deployed();

        const ADMIN_ROLE = await userContract.ADMIN_ROLE();
        const CANDIDATE_ROLE = await userContract.CANDIDATE_ROLE();
        const RECRUITER_ROLE = await userContract.RECRUITER_ROLE();

        await userContract.grantRole(admin.address, ADMIN_ROLE);
        await userContract.grantRole(admin2.address, ADMIN_ROLE);
        await userContract.addUser(candidate.address, 0);
        await userContract.addUser(recruiter.address, 1);

        return { userContract, companyContract, deployer, candidate, recruiter, admin, admin2, ADMIN_ROLE, CANDIDATE_ROLE, RECRUITER_ROLE };
    }

    describe("Deployment", function () {
        it("Should deployed", async function () {
            const { companyContract, deployer } = await loadFixture(deployFixture);

            console.log(companyContract.address);
        });
    });

    describe('Add company', () => {
        it("Should add company", async () => {
            const { companyContract, admin, admin2 } = await loadFixture(deployFixture);

            await companyContract.connect(admin).addCompany("fpt", "fpt.com", "quan 9", "");
            await companyContract.connect(admin2).addCompany("kms", "kms.com", "quan tan binh", "");

            console.log(await companyContract.getAllCompanies());
            expect((await companyContract.getAllCompanies()).length).to.equal(2);

            // const fpt = await companyContract.getCompany(1);
            // const kms = await companyContract.getCompany(2);

            // expect(fpt.name).to.equal("fpt");
            // expect(kms.name).to.equal("kms");
        });

        it("Should not add company for non-admin", async () => {
            const { companyContract, candidate, admin } = await loadFixture(deployFixture);

            await companyContract.connect(admin).addCompany("fpt", "fpt.com", "quan 9", "");

            // const tx = await companyContract.connect(candidate).addCompany("kms", "kms.com", "quan tan binh", "");
            // await tx.wait();
            // console.log(tx);

            await expect(companyContract.connect(candidate).addCompany("kms", "kms.com", "quan tan binh", "")).to.be.revertedWithCustomError(companyContract, "User__NoRole");

            // console.log(await companyContract.getAllCompanies());
            expect((await companyContract.getAllCompanies()).length).to.equal(1);
        });
    });

    describe('Update company', () => {
        it("Should update company", async () => {
            const { companyContract, admin } = await loadFixture(deployFixture);

            await companyContract.connect(admin).addCompany("fpt", "fpt.com", "quan 9", "");
            console.log(await companyContract.getCompany(1));

            await companyContract.connect(admin).updateCompany(1, "kms", "", "", "");
            console.log(await companyContract.getCompany(1));
        });

        it("Should not update company for non-admin", async () => {
            const { companyContract, candidate, admin } = await loadFixture(deployFixture);

            await companyContract.connect(admin).addCompany("fpt", "fpt.com", "quan 9", "");

            await expect(companyContract.connect(candidate).updateCompany(1, "kms", "", "", "")).to.revertedWithCustomError(companyContract, "User__NoRole");
        });

        it("Should not update company for another-admin", async () => {
            const { companyContract, admin, admin2 } = await loadFixture(deployFixture);

            await companyContract.connect(admin).addCompany("fpt", "fpt.com", "quan 9", "");

            await expect(companyContract.connect(admin2).updateCompany(1, "kms", "", "", "")).to.revertedWithCustomError(companyContract, "NotCreater");
        });

        it("Should not update company that not exist", async () => {
            const { companyContract, admin } = await loadFixture(deployFixture);

            await companyContract.connect(admin).addCompany("fpt", "fpt.com", "quan 9", "");
            console.log(await companyContract.getCompany(1));

            await expect(companyContract.connect(admin).updateCompany(2, "kms", "", "", "")).to.reverted;
        });

        describe('Remove company', () => {
            it("Should remove company", async () => {
                // const { companyContract, admin } = await loadFixture(deployFixture);

                // await companyContract.connect(admin).addCompany("fpt", "fpt.com", "quan 9", "");
                // console.log(await companyContract.getCompany(1));

                // await companyContract.updateCompany(1, "kms", "", "", "");
                // console.log(await companyContract.getCompany(1));
            })
        })
    });
})
