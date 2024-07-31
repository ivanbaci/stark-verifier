async function main() {
  const [deployer] = await ethers.getSigners();
  console.log('Deploying contracts with the account:', deployer.address);

  const StarkVerifier = await ethers.getContractFactory('StarkVerifier');
  const starkVerifier = await StarkVerifier.deploy();
  await starkVerifier.deployed();

  console.log('StarkVerifier deployed to:', starkVerifier.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
