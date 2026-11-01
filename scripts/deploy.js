// Deploys RoleManager first, then DrugBatch pointing at it.
// Usage: npm run deploy:local   (after `npm run node` in another terminal)
//        npm run deploy:sepolia (requires .env, see .env.example)
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with:", deployer.address);

  const roles = await hre.ethers.deployContract("RoleManager");
  await roles.waitForDeployment();
  console.log("RoleManager:", await roles.getAddress());

  const batches = await hre.ethers.deployContract("DrugBatch", [await roles.getAddress()]);
  await batches.waitForDeployment();
  console.log("DrugBatch:  ", await batches.getAddress());

  // TODO (interim demo): register sample manufacturer/distributor/pharmacy accounts.
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
