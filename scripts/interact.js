const hre = require('hardhat');

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log('Deploying contracts with the account:', deployer.address);

  const StarkVerifier = await hre.ethers.getContractFactory('StarkVerifier');
  const starkVerifier = await StarkVerifier.deploy();
  await starkVerifier.deployed();
  console.log('StarkVerifier deployed to:', starkVerifier.address);

  // establecer el Merkle root
  const root = hre.ethers.utils.keccak256(
    hre.ethers.utils.toUtf8Bytes('test root')
  );
  await starkVerifier.setMerkleRoot(root);
  console.log('Merkle root establecido:', root);

  // obtener primer punto aleatorio
  const tx = await starkVerifier.getRandomPoints();
  await tx.wait();
  const point = await starkVerifier.selectedPoints(0);
  console.log('Primer punto aleatorio seleccionado:', point);

  // establecer los roots de los CPS
  const roots = Array(11).fill(
    hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes('test root'))
  );
  await starkVerifier.setCpRoots(roots);
  console.log('Roots de los CPs establecidos');
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
