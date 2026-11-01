const { expect } = require("chai");
const { ethers } = require("hardhat");

// Smoke tests for the design draft: contracts deploy and wiring is correct.
// Full custody-flow tests (mint -> ship -> receive -> dispense, recall, role checks)
// will be added as functions are implemented.
describe("MedChain deployment", function () {
  it("deploys RoleManager with the deployer as regulator", async function () {
    const [regulator] = await ethers.getSigners();
    const roles = await ethers.deployContract("RoleManager");
    expect(await roles.isAuthorized(regulator.address, await roles.REGULATOR_ROLE())).to.equal(true);
  });

  it("deploys DrugBatch linked to RoleManager", async function () {
    const roles = await ethers.deployContract("RoleManager");
    const batches = await ethers.deployContract("DrugBatch", [await roles.getAddress()]);
    expect(await batches.roles()).to.equal(await roles.getAddress());
    expect(await batches.name()).to.equal("MedChain Drug Batch");
  });
});
