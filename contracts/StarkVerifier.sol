// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract StarkVerifier {
    uint256 constant PRIME = 322122547; 
    uint256 constant LARGE_DOMAIN_SIZE = 8192;
    uint256 constant GENERATOR = 3;
    uint256 constant NUM_POINTS = 4;

    // Coeficientes de la combinación lineal para cp0(x) (elegidos arbitrariamente, se podrían elegir otros o recibir del prover)
    uint256 constant ALPHA_0 = 1;
    uint256 constant ALPHA_1 = 2;
    uint256 constant ALPHA_2 = 3;

    bytes32 public merkleRoot;
    bytes32[] public cpRoots;
    uint256[] public selectedPoints;

    function setMerkleRoot(bytes32 _merkleRoot) public {
        merkleRoot = _merkleRoot;
    }
    
    function setCpRoots(bytes32[] memory _cpRoots) public {
        require(_cpRoots.length == 11, "Debe proporcionar los roots para cp0, cp1, ..., cp10");
        delete cpRoots;
        for (uint256 i = 0; i < 11; i++) {
            cpRoots.push(_cpRoots[i]);
        }
    }

    function getRandomPoints() public returns (uint256[] memory) {
        uint256[] memory domain = calculateExtendedDomain();
        delete selectedPoints;
        for (uint256 i = 0; i < NUM_POINTS; i++) {
            uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, i))) % LARGE_DOMAIN_SIZE;
            selectedPoints.push(domain[randomIndex]);
        }
        return selectedPoints;
    }

    function hash(bytes memory input) public pure returns (bytes32) {
        return keccak256(input);
    }

    function calculateExtendedDomain() public pure returns (uint256[] memory) {
        uint256[] memory domain = new uint256[](LARGE_DOMAIN_SIZE);
        uint256 g = GENERATOR;
        uint256 current = 1;
        for (uint256 i = 0; i < LARGE_DOMAIN_SIZE; i++) {
            domain[i] = current;
            current = (current * g) % PRIME;
        }
        return domain;
    }

    function verifyMerklePath(bytes32 leaf, bytes32[] memory path, bytes32 root) public pure returns (bool) {
        bytes32 hashVal = leaf;
        for (uint256 i = 0; i < path.length; i++) {
            hashVal = hash(abi.encodePacked(hashVal, path[i]));
        }
        return hashVal == root;
    }

    function isSelectedPoint(uint256 x) public view returns (bool) {
        for (uint256 i = 0; i < selectedPoints.length; i++) {
            if (selectedPoints[i] == x) {
                return true;
            }
        }
        return false;
    }

    function verify(
        uint256 x, // Punto de evaluación
        uint256 f_x, // Evaluación de f(x)
        bytes32[] memory f_x_path, // Camino de Merkle para f(x)
        uint256 f_gx, // Evaluación de f(gx)
        bytes32[] memory f_gx_path, // Camino de Merkle para f(gx)
        uint256 f_g2x, // Evaluación de f(g^2x)
        bytes32[] memory f_g2x_path, // Camino de Merkle para f(g^2x)
        uint256 cp0_x, // Evaluación de cp0(x)
        bytes32[] memory cp0_x_path, // Camino de Merkle para cp0(x)
        uint256 cp0_neg_x, // Evaluación de cp0(-x)
        bytes32[] memory cp0_neg_x_path, // Camino de Merkle para cp0(-x)
        uint256 cp1_x2, // Evaluación de cp1(x^2)
        bytes32[] memory cp1_x2_path // Camino de Merkle para cp1(x^2)
    ) public view returns (bool) {
        if (!isSelectedPoint(x)) {
            return false;
        }

        if (!verifyMerklePath(bytes32(f_x), f_x_path, merkleRoot)) {
            return false;
        }
        if (!verifyMerklePath(bytes32(f_gx), f_gx_path, merkleRoot)) {
            return false;
        }
        if (!verifyMerklePath(bytes32(f_g2x), f_g2x_path, merkleRoot)) {
            return false;
        }

        // Calcular cp0(x) como una combinación lineal de f(x), f(gx) y f(g^2x)
        uint256 computed_cp0_x = (ALPHA_0 * f_x + ALPHA_1 * f_gx + ALPHA_2 * f_g2x) % PRIME;

        // Verificar que el cp0(x) calculado corresponde al cp0(x) proporcionado por el prover
        if (computed_cp0_x != cp0_x) {
            return false;
        }

        // Verificar que cp0(x) pertenece al árbol de Merkle del root de cp0
        if (!verifyMerklePath(bytes32(cp0_x), cp0_x_path, cpRoots[0])) {
            return false;
        }

         // Verificar que cp0(-x) pertenece al árbol de Merkle del root de cp0
        if (!verifyMerklePath(bytes32(cp0_neg_x), cp0_neg_x_path, cpRoots[0])) {
            return false;
        }

        // Verificar que cp1(x^2) pertenece al árbol de Merkle del root de cp1
        if (!verifyMerklePath(bytes32(cp1_x2), cp1_x2_path, cpRoots[1])) {
            return false;
        }

        // Verificar que cp0(x) + cp0(-x) = cp1(x^2)
        if ((cp0_x + cp0_neg_x) % PRIME != cp1_x2) {
            return false;
        }

        return true;
    }
}
