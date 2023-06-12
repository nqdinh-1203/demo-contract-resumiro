import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

describe('Certificate', () => {
    async function deployFixture() {
        const [deployer, candidate, candidate2, admin_company, admin_company2, user] = await ethers.getSigners();

        const userFactory = await ethers.getContractFactory("User", deployer);
        const userContract = await userFactory.deploy();
        await userContract.deployed();

        const companyFactory = await ethers.getContractFactory("Company", deployer);
        const companyContract = await companyFactory.deploy(userContract.address);
        await companyContract.deployed();

        const certFactory = await ethers.getContractFactory("Certificate", deployer);
        const certContract = await certFactory.deploy(userContract.address, companyContract.address);
        await certContract.deployed();

        const resumiroFactory = await ethers.getContractFactory("Resumiro", deployer);
        const resumiroContract = await resumiroFactory.deploy(userContract.address, companyContract.address, certContract.address, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS);

        await resumiroContract.connect(candidate).addUser(candidate.address, 0);
        await resumiroContract.connect(candidate2).addUser(candidate2.address, 0);
        await resumiroContract.connect(admin_company).addUser(admin_company.address, 2);
        await resumiroContract.connect(admin_company2).addUser(admin_company2.address, 2);

        await resumiroContract.connect(admin_company).addCompany("toeic", "toeic.com", "quan 9", "");
        await resumiroContract.connect(admin_company2).addCompany("ielts", "ielts.com", "quan tan binh", "");

        const allCompanies = await resumiroContract.getAllCompanies();

        return { certContract, resumiroContract, deployer, candidate, candidate2, admin_company, admin_company2, user, allCompanies };
    }

    describe('Deployment', () => {
        it("Should deployed", async function () {
            const { resumiroContract } = await loadFixture(deployFixture);

            console.log(resumiroContract.address);
        });
    })

    describe('Add Certificate', () => {
        it("Should add cert", async function () {
            const { resumiroContract, candidate, admin_company, admin_company2 } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", "xyz.com", candidate.address, admin_company.address, 1);
            await resumiroContract.connect(candidate).addCertificate("ielts 9.0", "abc.com", candidate.address, admin_company2.address, 2);

            // const cert1 = await resumiroContract.getCertificate("xyz.com");
            // const cert2 = await resumiroContract.getCertificate("abc.com");

            // console.log(cert1);
            // console.log(cert2);

            const allCertsOfCandidate = await resumiroContract.connect(candidate).getCertificateCandidate(candidate.address);
            // console.log(allCertsOfCandidate);
            expect(allCertsOfCandidate.length).to.equal(2);

            expect(allCertsOfCandidate[0].name).to.equal("toeic 990");
            expect(allCertsOfCandidate[0].status).to.equal(0);
            expect(allCertsOfCandidate[0].candidate).to.equal(candidate.address);

            expect(allCertsOfCandidate[1].name).to.equal("ielts 9.0");
            expect(allCertsOfCandidate[1].status).to.equal(0);
            expect(allCertsOfCandidate[1].candidate).to.equal(candidate.address);
        });
        it("Should not add by non-candidate", async () => {
            const { resumiroContract, certContract, user, admin_company } = await loadFixture(deployFixture);

            await expect(resumiroContract.connect(user).addCertificate("toeic 990", "xyz.com", user.address, admin_company.address, 1)).to.revertedWithCustomError(certContract, "User__NoRole");
        });
        it("Should not add for another candidate", async () => {
            const { resumiroContract, certContract, candidate, candidate2, admin_company } = await loadFixture(deployFixture);

            await expect(resumiroContract.connect(candidate).addCertificate("toeic 990", "xyz.com", candidate2.address, admin_company.address, 1)).to.revertedWithCustomError(certContract, 'Cert_Candidate__NotForSelf');
        });
        it("Should not add for admin-company is not creator of company", async () => {
            const { resumiroContract, certContract, candidate, admin_company2 } = await loadFixture(deployFixture);

            await expect(resumiroContract.connect(candidate).addCertificate("toeic 990", "xyz.com", candidate.address, admin_company2.address, 1)).to.revertedWithCustomError(certContract, 'Verifier__NotCreator');
        })
    });

    describe('Update Certificate', () => {
        it("Should update cert", async function () {
            const { resumiroContract, candidate, admin_company, admin_company2 } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", "xyz.com", candidate.address, admin_company.address, 1);
            await resumiroContract.connect(candidate).addCertificate("ielts 9.0", "abc.com", candidate.address, admin_company2.address, 2);

            // const cert1 = await resumiroContract.getCertificate("xyz.com");
            // const cert2 = await resumiroContract.getCertificate("abc.com");

            // console.log(cert1);
            // console.log(cert2);

            await resumiroContract.connect(candidate).updateCertificate(1, "toeic 666", "qwe.vn", admin_company.address, 1);
            const cert1 = await resumiroContract.connect(candidate).getCertificate("qwe.vn");
            // console.log(cert1);
            expect(cert1.name).to.equal("toeic 666");

        });
        it("Should not update by non-candidate", async () => {
            const { resumiroContract, certContract, candidate, admin_company, user } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", "xyz.com", candidate.address, admin_company.address, 1);

            await expect(resumiroContract.connect(user).updateCertificate(1, "toeic 666", "qwe.vn", admin_company.address, 1)).to.revertedWithCustomError(certContract, "User__NoRole");
        });
        it("Should not update by not owned candidate", async () => {
            const { resumiroContract, certContract, candidate, admin_company, candidate2 } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", "xyz.com", candidate.address, admin_company.address, 1);

            await expect(resumiroContract.connect(candidate2).updateCertificate(1, "toeic 666", "qwe.vn", admin_company.address, 1)).to.revertedWithCustomError(certContract, "Cert_Candidate__NotOwned");
        });

        it("Should not update for admin-company is not creator of company", async () => {
            const { resumiroContract, certContract, candidate, admin_company } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", "xyz.com", candidate.address, admin_company.address, 1);

            await expect(resumiroContract.connect(candidate).updateCertificate(1, "toeic 666", "qwe.vn", admin_company.address, 2)).to.revertedWithCustomError(certContract, "Verifier__NotCreator")
        })
        // it("Should not update rejected/verified cert", async () => {
        //     const { resumiroContract, candidate, admin_company, admin_company2 } = await loadFixture(deployFixture);

        //     await resumiroContract.connect(candidate).addCertificate("toeic 990", candidate.address, admin_company.address, "xyz.com");
        //     await resumiroContract.connect(candidate).addCertificate("ielts 9.0", candidate.address, admin_company2.address, "abc.com");
        // })
    });

    describe('Change cert status', () => {
        it("Should change status", async () => {
            const { resumiroContract, candidate, admin_company, admin_company2 } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", "xyz.com", candidate.address, admin_company.address, 1);
            await resumiroContract.connect(candidate).addCertificate("ielts 9.0", "abc.com", candidate.address, admin_company2.address, 2);

            const now = Date.now();

            await resumiroContract.connect(admin_company).changeCertificateStatus(1, 1, now); // verified
            await resumiroContract.connect(admin_company2).changeCertificateStatus(2, 2, now); // rejected

            const allCertsOfCandidate = await resumiroContract.connect(candidate).getCertificateCandidate(candidate.address);
            // console.log(allCertsOfCandidate);
            expect(allCertsOfCandidate[0].status).to.equal(1);
            expect(allCertsOfCandidate[1].status).to.equal(2);
        })

        it("Should not change status by non-admin_company", async () => {
            const { resumiroContract, certContract, candidate, admin_company, user } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", "xyz.com", candidate.address, admin_company.address, 1);

            const now = Date.now();

            await expect(resumiroContract.connect(candidate).changeCertificateStatus(1, 1, now)).to.revertedWithCustomError(certContract, "User__NoRole");
            await expect(resumiroContract.connect(user).changeCertificateStatus(1, 1, now)).to.revertedWithCustomError(certContract, "User__NoRole");
        })

        it("Should not change status by not setted admin_company", async () => {
            const { resumiroContract, certContract, candidate, admin_company, admin_company2 } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", "xyz.com", candidate.address, admin_company.address, 1);

            const now = Date.now();

            await expect(resumiroContract.connect(admin_company2).changeCertificateStatus(1, 1, now)).to.revertedWithCustomError(certContract, "Cert_Verifier__NotVerifierOfCertificate");
        })

        it("Should not change status of rejected cert", async () => {
            const { resumiroContract, certContract, candidate, admin_company } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", "xyz.com", candidate.address, admin_company.address, 1);

            const now = Date.now();

            await resumiroContract.connect(admin_company).changeCertificateStatus(1, 2, now); // rejected

            await expect(resumiroContract.connect(admin_company).changeCertificateStatus(1, 1, now)).to.revertedWithCustomError(certContract, "Cert__Rejected");
        })

        it("Should not update rejected/verified cert", async () => {
            const { resumiroContract, certContract, candidate, admin_company, admin_company2 } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", "xyz.com", candidate.address, admin_company.address, 1);
            await resumiroContract.connect(candidate).addCertificate("ielts 9.0", "abc.com", candidate.address, admin_company2.address, 2);

            const now = Date.now();

            await resumiroContract.connect(admin_company).changeCertificateStatus(1, 1, now); // verified
            await resumiroContract.connect(admin_company2).changeCertificateStatus(2, 2, now); // rejected

            await expect(resumiroContract.connect(candidate).updateCertificate(1, "toeic 666", "qwe.vn", admin_company.address, 1)).to.revertedWithCustomError(certContract, "Cert__NotPending");
            await expect(resumiroContract.connect(candidate).updateCertificate(2, "toeic 777", "xxx.vn", admin_company2.address, 2)).to.revertedWithCustomError(certContract, "Cert__NotPending");
        })
    });

    describe('Delete Certificate', () => {
        it("Should delete cert", async function () {
            const { resumiroContract, candidate, admin_company, admin_company2 } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", "xyz.com", candidate.address, admin_company.address, 1);
            await resumiroContract.connect(candidate).addCertificate("ielts 9.0", "abc.com", candidate.address, admin_company2.address, 2);

            await resumiroContract.connect(candidate).deleteCertificate(1);
            const cert1 = await resumiroContract.connect(candidate).getCertificate("xyz.com");
            console.log(cert1);
            expect(cert1.name).to.equal("");

            const allCertsOfCandidate = await resumiroContract.connect(candidate).getCertificateCandidate(candidate.address);
            expect(allCertsOfCandidate.length).to.eq(1);
        });
        it("Should not delete by non-candidate", async () => {
            const { resumiroContract, certContract, candidate, admin_company, user } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", "xyz.com", candidate.address, admin_company.address, 1);

            await expect(resumiroContract.connect(user).deleteCertificate(1)).to.revertedWithCustomError(certContract, "User__NoRole");
        });
        it("Should not delete by not owned candidate", async () => {
            const { resumiroContract, certContract, candidate, admin_company, candidate2 } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", "xyz.com", candidate.address, admin_company.address, 1);

            await expect(resumiroContract.connect(candidate2).deleteCertificate(1)).to.revertedWithCustomError(certContract, "Cert_Candidate__NotOwned");
        });
    });
})
