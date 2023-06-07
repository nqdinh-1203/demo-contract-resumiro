import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

describe('Certificate', () => {
    async function deployFixture() {
        const [deployer, candidate, candidate2, verifier, verifier2, user] = await ethers.getSigners();

        const userFactory = await ethers.getContractFactory("User", deployer);
        const userContract = await userFactory.deploy();
        await userContract.deployed();

        const certFactory = await ethers.getContractFactory("Certificate", deployer);
        const certContract = await certFactory.deploy(userContract.address);
        await certContract.deployed();

        const resumiroFactory = await ethers.getContractFactory("Resumiro", deployer);
        const resumiroContract = await resumiroFactory.deploy(userContract.address, ZERO_ADDRESS, certContract.address, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS);

        await resumiroContract.addUser(candidate.address, 0);
        await resumiroContract.addUser(candidate2.address, 0);
        await resumiroContract.addUser(verifier.address, 2);
        await resumiroContract.addUser(verifier2.address, 2);

        return { certContract, resumiroContract, deployer, candidate, candidate2, verifier, verifier2, user };
    }

    describe('Deployment', () => {
        it("Should deployed", async function () {
            const { resumiroContract } = await loadFixture(deployFixture);

            console.log(resumiroContract.address);
        });
    })

    describe('Add Certificate', () => {
        it("Should add cert", async function () {
            const { resumiroContract, candidate, verifier, verifier2 } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", candidate.address, verifier.address, "xyz.com");
            await resumiroContract.connect(candidate).addCertificate("ielts 9.0", candidate.address, verifier2.address, "abc.com");

            // const cert1 = await resumiroContract.getCertificate("xyz.com");
            // const cert2 = await resumiroContract.getCertificate("abc.com");

            // console.log(cert1);
            // console.log(cert2);

            const allCertsOfCandidate = await resumiroContract.connect(candidate).getCertificateCandidate(candidate.address);
            // console.log(allCertsOfCandidate);
            expect(allCertsOfCandidate.length).to.equal(2);
            expect(allCertsOfCandidate[0].name).to.equal("toeic 990");
            expect(allCertsOfCandidate[1].name).to.equal("ielts 9.0");
        });
        it("Should not add by non-candidate", async () => {
            const { resumiroContract, certContract, user, verifier } = await loadFixture(deployFixture);

            await expect(resumiroContract.connect(user).addCertificate("toeic 990", user.address, verifier.address, "xyz.com")).to.revertedWithCustomError(certContract, "User__NoRole");
        });
        it("Should not add for another candidate", async () => {
            const { resumiroContract, certContract, candidate, candidate2, verifier } = await loadFixture(deployFixture);

            await expect(resumiroContract.connect(candidate).addCertificate("toeic 990", candidate2.address, verifier.address, "xyz.com")).to.revertedWith('param and call not match');
        });
    });

    describe('Update Certificate', () => {
        it("Should update cert", async function () {
            const { resumiroContract, candidate, verifier, verifier2 } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", candidate.address, verifier.address, "xyz.com");
            await resumiroContract.connect(candidate).addCertificate("ielts 9.0", candidate.address, verifier2.address, "abc.com");

            // const cert1 = await resumiroContract.getCertificate("xyz.com");
            // const cert2 = await resumiroContract.getCertificate("abc.com");

            // console.log(cert1);
            // console.log(cert2);

            await resumiroContract.connect(candidate).updateCertificate(1, "toeic 666", verifier.address, "qwe.vn");
            const cert1 = await resumiroContract.connect(candidate).getCertificate("qwe.vn");
            // console.log(cert1);
            expect(cert1.name).to.equal("toeic 666");

        });
        it("Should not update by non-candidate", async () => {
            const { resumiroContract, certContract, candidate, verifier, user } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", candidate.address, verifier.address, "xyz.com");

            await expect(resumiroContract.connect(user).updateCertificate(1, "toeic 666", verifier.address, "qwe.vn")).to.revertedWithCustomError(certContract, "User__NoRole");
        });
        it("Should not update by not owned candidate", async () => {
            const { resumiroContract, certContract, candidate, verifier, candidate2 } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", candidate.address, verifier.address, "xyz.com");

            await expect(resumiroContract.connect(candidate2).updateCertificate(1, "toeic 666", verifier.address, "qwe.vn")).to.revertedWithCustomError(certContract, "Cert_Candidate__NotOwned");
        });
        // it("Should not update rejected/verified cert", async () => {
        //     const { resumiroContract, candidate, verifier, verifier2 } = await loadFixture(deployFixture);

        //     await resumiroContract.connect(candidate).addCertificate("toeic 990", candidate.address, verifier.address, "xyz.com");
        //     await resumiroContract.connect(candidate).addCertificate("ielts 9.0", candidate.address, verifier2.address, "abc.com");
        // })
    });

    describe('Change cert status', () => {
        it("Should change status", async () => {
            const { resumiroContract, candidate, verifier, verifier2 } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", candidate.address, verifier.address, "xyz.com");
            await resumiroContract.connect(candidate).addCertificate("ielts 9.0", candidate.address, verifier2.address, "abc.com");

            const now = Date.now(); 
            
            await resumiroContract.connect(verifier).changeCertificateStatus(1, 1, now);
            await resumiroContract.connect(verifier2).changeCertificateStatus(2, 2, now);
            
            const allCertsOfCandidate = await resumiroContract.connect(candidate).getCertificateCandidate(candidate.address);
            // console.log(allCertsOfCandidate);
            expect(allCertsOfCandidate[0].status).to.equal(1);
            expect(allCertsOfCandidate[1].status).to.equal(2);
        })

        it("Should not change status by non-verifier", async () => {
            const { resumiroContract, certContract, candidate, verifier, user } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", candidate.address, verifier.address, "xyz.com");

            const now = Date.now(); 
            
            await expect(resumiroContract.connect(candidate).changeCertificateStatus(1, 1, now)).to.revertedWithCustomError(certContract, "User__NoRole");
            await expect(resumiroContract.connect(user).changeCertificateStatus(1, 1, now)).to.revertedWithCustomError(certContract, "User__NoRole");
        })

        it("Should not change status by not setted verifier", async () => {
            const { resumiroContract, certContract, candidate, verifier, verifier2 } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", candidate.address, verifier.address, "xyz.com");

            const now = Date.now(); 
            
            await expect(resumiroContract.connect(verifier2).changeCertificateStatus(1, 1, now)).to.revertedWithCustomError(certContract, "Cert_Verifier__NotVerifierOfCertificate");
        })

        it("Should not change status of rejected cert", async () => {
            const { resumiroContract, certContract, candidate, verifier } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", candidate.address, verifier.address, "xyz.com");

            const now = Date.now(); 
            
            await resumiroContract.connect(verifier).changeCertificateStatus(1, 2, now); // rejected
            
            await expect(resumiroContract.connect(verifier).changeCertificateStatus(1, 1, now)).to.revertedWithCustomError(certContract, "Cert__Rejected");
        })

        it("Should not update rejected/verified cert", async () => {
            const { resumiroContract, certContract, candidate, verifier, verifier2 } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", candidate.address, verifier.address, "xyz.com");
            await resumiroContract.connect(candidate).addCertificate("ielts 9.0", candidate.address, verifier2.address, "abc.com");

            const now = Date.now(); 
            
            await resumiroContract.connect(verifier).changeCertificateStatus(1, 1, now); // verified
            await resumiroContract.connect(verifier2).changeCertificateStatus(2, 2, now); // rejected

            await expect(resumiroContract.connect(candidate).updateCertificate(1, "toeic 666", verifier.address, "qwe.vn")).to.revertedWithCustomError(certContract, "Cert__NotPending");
            await expect(resumiroContract.connect(candidate).updateCertificate(2, "toeic 777", verifier.address, "xxx.vn")).to.revertedWithCustomError(certContract, "Cert__NotPending");
        })
    });

    describe('Delete Certificate', () => {
        it("Should delete cert", async function () {
            const { resumiroContract, candidate, verifier, verifier2 } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", candidate.address, verifier.address, "xyz.com");
            await resumiroContract.connect(candidate).addCertificate("ielts 9.0", candidate.address, verifier2.address, "abc.com");

            await resumiroContract.connect(candidate).deleteCertificate(1);
            const cert1 = await resumiroContract.connect(candidate).getCertificate("xyz.com");
            console.log(cert1);
            expect(cert1.name).to.equal("");

            const allCertsOfCandidate = await resumiroContract.connect(candidate).getCertificateCandidate(candidate.address);
            expect(allCertsOfCandidate.length).to.eq(1);
        });
        it("Should not delete by non-candidate", async () => {
            const { resumiroContract, certContract, candidate, verifier, user } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", candidate.address, verifier.address, "xyz.com");

            await expect(resumiroContract.connect(user).deleteCertificate(1)).to.revertedWithCustomError(certContract, "User__NoRole");
        });
        it("Should not delete by not owned candidate", async () => {
            const { resumiroContract, certContract, candidate, verifier, candidate2 } = await loadFixture(deployFixture);

            await resumiroContract.connect(candidate).addCertificate("toeic 990", candidate.address, verifier.address, "xyz.com");

            await expect(resumiroContract.connect(candidate2).deleteCertificate(1)).to.revertedWithCustomError(certContract, "Cert_Candidate__NotOwned");
        });
    });
})
