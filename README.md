# Stark Verifier Contract

Dentro del contrato StarkVerifier.sol hay tres funciones públicas para que use un prover:

- **setMerkleRoot**: trace root commitment.
- **setCpRoots**: CPs roots commitments.
- **verify**: para que el prover mande los datos para que el verifier valide (decommitment)

## Deployment

Para desplegar el contrato de manera local

```
npx hardhat node
```

```
npx hardhat run --network localhost scripts/deploy.js
```

También se puede correr el script `interactions.js` que deploya el contrato e interactúa con las funciones del mismo.

```
npx hardhat run --network localhost scripts/interact.js
```

## Testing

```shell
npx hardhat test
```
