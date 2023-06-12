import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

describe("Company", function () {
    async function deployFixture() {
        const [deployer, candidate, recruiter, recruiter2, recruiter3, admin_company, admin_company2] = await ethers.getSigners();

        const userFactory = await ethers.getContractFactory("User", deployer);
        const userContract = await userFactory.deploy();
        await userContract.deployed();

        const companyFactory = await ethers.getContractFactory("Company", deployer);
        const companyContract = await companyFactory.deploy(userContract.address);
        await companyContract.deployed();

        const resumiroFactory = await ethers.getContractFactory("Resumiro", deployer);
        const resumiroContract = await resumiroFactory.deploy(userContract.address, companyContract.address, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS);

        await resumiroContract.connect(admin_company).addUser(admin_company.address, 2);
        await resumiroContract.connect(admin_company2).addUser(admin_company2.address, 2);
        await resumiroContract.connect(candidate).addUser(candidate.address, 0);
        await resumiroContract.connect(recruiter).addUser(recruiter.address, 1);
        await resumiroContract.connect(recruiter2).addUser(recruiter2.address, 1);
        await resumiroContract.connect(recruiter3).addUser(recruiter3.address, 1);

        return { resumiroContract, companyContract, deployer, candidate, recruiter, recruiter2, recruiter3, admin_company, admin_company2 };
    }

    describe("Deployment", function () {
        it("Should deployed", async function () {
            const { resumiroContract, deployer } = await loadFixture(deployFixture);

            console.log(resumiroContract.address);
        });
    });

    describe('Add company', () => {
        it("Should add company", async () => {
            const { resumiroContract, admin_company, admin_company2 } = await loadFixture(deployFixture);

            await resumiroContract.connect(admin_company).addCompany("fpt", "fpt.com", "quan 9", "");
            await resumiroContract.connect(admin_company2).addCompany("kms", "kms.com", "quan tan binh", "");

            const allCompanies = await resumiroContract.getAllCompanies();
            // console.log(allCompanies);
            expect(allCompanies.length).to.equal(2);
            expect(await resumiroContract.isCreator(1, admin_company.address)).to.equal(true);
            expect(await resumiroContract.isCreator(2, admin_company2.address)).to.equal(true);

            // const fpt = await resumiroContract.getCompany(1);
            // const kms = await resumiroContract.getCompany(2);

            // expect(fpt.name).to.equal("fpt");
            // expect(kms.name).to.equal("kms");
        });

        it("Should not add company for non-admin_company", async () => {
            const { resumiroContract, companyContract, candidate, admin_company } = await loadFixture(deployFixture);

            await resumiroContract.connect(admin_company).addCompany("fpt", "fpt.com", "quan 9", "");

            // const tx = await resumiroContract.connect(candidate).addCompany("kms", "kms.com", "quan tan binh", "");
            // await tx.wait();
            // console.log(tx);

            await expect(resumiroContract.connect(candidate).addCompany("kms", "kms.com", "quan tan binh", "")).to.be.revertedWithCustomError(companyContract, "User__NoRole");

            // console.log(await resumiroContract.getAllCompanies());
            expect((await resumiroContract.getAllCompanies()).length).to.equal(1);
        });
    });

    describe('Update company', () => {
        it("Should update company", async () => {
            const { resumiroContract, admin_company } = await loadFixture(deployFixture);

            await resumiroContract.connect(admin_company).addCompany("fpt", "fpt.com", "quan 9", "");
            // console.log(await resumiroContract.getCompany(1));

            await resumiroContract.connect(admin_company).updateCompany(1, "kms", "", "", "");
            // console.log(await resumiroContract.getCompany(1));

            const c1 = await resumiroContract.getCompany(1);
            expect(c1.name).to.equal("kms");
        });

        it("Should not update company for non-admin_company", async () => {
            const { resumiroContract, companyContract, candidate, admin_company } = await loadFixture(deployFixture);

            await resumiroContract.connect(admin_company).addCompany("fpt", "fpt.com", "quan 9", "");

            await expect(resumiroContract.connect(candidate).updateCompany(1, "kms", "", "", "")).to.revertedWithCustomError(companyContract, "User__NoRole");
        });

        it("Should not update company for not-creator", async () => {
            const { resumiroContract, companyContract, admin_company, admin_company2 } = await loadFixture(deployFixture);

            await resumiroContract.connect(admin_company).addCompany("fpt", "fpt.com", "quan 9", "");

            await expect(resumiroContract.connect(admin_company2).updateCompany(1, "kms", "", "", "")).to.revertedWithCustomError(companyContract, "Company__NotCreator");
        });

        it("Should not update company that not exist", async () => {
            const { resumiroContract, admin_company } = await loadFixture(deployFixture);

            await resumiroContract.connect(admin_company).addCompany("fpt", "fpt.com", "quan 9", "");
            // console.log(await resumiroContract.getCompany(1));

            await expect(resumiroContract.connect(admin_company).updateCompany(2, "kms", "", "", "")).to.reverted;
        });
    });

    describe('Remove company', () => {
        it("Should remove company", async () => {
            const { resumiroContract, admin_company } = await loadFixture(deployFixture);

            await resumiroContract.connect(admin_company).addCompany("fpt", "fpt.com", "quan 9", "");
            // console.log(await resumiroContract.getCompany(1));

            await resumiroContract.connect(admin_company).deleteCompany(1);

            // console.log(await resumiroContract.getCompany(1));
            const allCompanies = await resumiroContract.getAllCompanies();
            // console.log(allCompanies);
            expect(allCompanies.length).to.equal(0);
        })

        it("Should not remove company for non-admin_company", async () => {
            const { resumiroContract, companyContract, candidate, admin_company } = await loadFixture(deployFixture);

            await resumiroContract.connect(admin_company).addCompany("fpt", "fpt.com", "quan 9", "");

            await expect(resumiroContract.connect(candidate).deleteCompany(1)).to.revertedWithCustomError(companyContract, "User__NoRole");
        });

        it("Should not remove company for not-creator", async () => {
            const { resumiroContract, companyContract, admin_company, admin_company2 } = await loadFixture(deployFixture);

            await resumiroContract.connect(admin_company).addCompany("fpt", "fpt.com", "quan 9", "");

            await expect(resumiroContract.connect(admin_company2).deleteCompany(1)).to.revertedWithCustomError(companyContract, "Company__NotCreator");
        });

        it("Should not update company that not exist", async () => {
            const { resumiroContract, admin_company } = await loadFixture(deployFixture);

            await resumiroContract.connect(admin_company).addCompany("fpt", "fpt.com", "quan 9", "");
            // console.log(await resumiroContract.getCompany(1));

            await expect(resumiroContract.connect(admin_company).deleteCompany(2)).to.reverted;
        });
    });

    describe('Recruiter-Company', () => {
        it("Should connect", async () => {
            const { resumiroContract, recruiter, recruiter2, admin_company, admin_company2 } = await loadFixture(deployFixture);

            await resumiroContract.connect(admin_company).addCompany("fpt", "fpt.com", "quan 9", "");
            await resumiroContract.connect(admin_company2).addCompany("kms", "kms.com", "quan tan binh", "");

            // await resumiroContract.connect(admin_company).connectCompanyRecruiter(recruiter.address, 1);
            await resumiroContract.connect(admin_company2).connectCompanyRecruiter(recruiter.address, 2);
            await resumiroContract.connect(admin_company2).connectCompanyRecruiter(recruiter2.address, 2);

            const companiesIn = await resumiroContract.getAllCompaniesConnectedUser(recruiter.address);
            console.log(companiesIn);

            const recruiterIn = await resumiroContract.getAllUsersConnectedCompany(2);
            console.log(recruiterIn);
        });

        it("Should disconnect", async () => {
            const { resumiroContract, recruiter, recruiter2, admin_company, admin_company2 } = await loadFixture(deployFixture);

            await resumiroContract.connect(admin_company).addCompany("fpt", "fpt.com", "quan 9", "");
            await resumiroContract.connect(admin_company2).addCompany("kms", "kms.com", "quan tan binh", "");

            // await resumiroContract.connect(admin_company).connectCompanyRecruiter(recruiter.address, 1);
            await resumiroContract.connect(admin_company2).connectCompanyRecruiter(recruiter.address, 2);
            await resumiroContract.connect(admin_company2).connectCompanyRecruiter(recruiter2.address, 2);

            await resumiroContract.connect(admin_company2).disconnectCompanyUser(recruiter.address, 2);

            const recruiterIn = await resumiroContract.getAllUsersConnectedCompany(2);
            console.log(recruiterIn);
        });
    })
})
