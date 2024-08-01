// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract StarkVerifier {
    uint256 constant PRIME = 322122547; 
    uint256 constant LARGE_DOMAIN_SIZE = 8192;
    uint256 constant GENERATOR = 3;
    uint256 constant NUM_POINTS = 4;

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
        uint256[] memory cp_evals, // Evaluaciones de cp0(x), cp1(x^2), ..., cp10(x^1024)
        uint256[] memory cp_neg_evals, // Evaluaciones de cp0(-x), cp1(-x^2), ..., cp10(-x^1024)
        bytes32[][] memory cp_paths, // Caminos de Merkle para cada cp eval
        bytes32[][] memory cp_neg_paths, // Caminos de Merkle para cada cp neg eval
        uint256[] memory alphas // Coeficientes de la combinación lineal para cp0(x)
    ) public view returns (bool) {
        require(cp_evals.length == 11, "Debe proporcionar 11 evaluaciones de cp(x)");
        require(cp_neg_evals.length == 11, "Debe proporcionar 11 evaluaciones de cp(-x)");
        require(cp_paths.length == 11, "Debe proporcionar 11 caminos de Merkle para cp(x)");
        require(cp_neg_paths.length == 11, "Debe proporcionar 11 caminos de Merkle para cp(-x)");
        require(alphas.length == 3, "Debe proporcionar 3 coeficientes alfa");

        // Verificar que x y -x están dentro de los puntos seleccionados
        if (!isSelectedPoint(x) || !isSelectedPoint(PRIME - x)) {
            return false;
        }

        // Verificar las evaluaciones de f(x), f(gx) y f(g^2x) en el árbol de Merkle
        if (!verifyMerklePath(bytes32(f_x), f_x_path, merkleRoot)) {
            return false;
        }
        if (!verifyMerklePath(bytes32(f_gx), f_gx_path, merkleRoot)) {
            return false;
        }
        if (!verifyMerklePath(bytes32(f_g2x), f_g2x_path, merkleRoot)) {
            return false;
        }

        // Calcular cp0(x) como una combinación lineal de f(x), f(gx) y f(g^2x) usando los coeficientes alfa proporcionados
        uint256 computed_cp0_x = (alphas[0] * f_x + alphas[1] * f_gx + alphas[2] * f_g2x) % PRIME;

        // Verificar que el cp0(x) calculado corresponde al cp0(x) proporcionado por el prover
        if (computed_cp0_x != cp_evals[0]) {
            return false;
        }

        // Verificar que cp0(x) pertenece al árbol de Merkle del root de cp0
        if (!verifyMerklePath(bytes32(cp_evals[0]), cp_paths[0], cpRoots[0])) {
            return false;
        }

        // Verificar que cp0(-x) pertenece al árbol de Merkle del root de cp0
        if (!verifyMerklePath(bytes32(cp_neg_evals[0]), cp_neg_paths[0], cpRoots[0])) {
            return false;
        }

        // Verificar los niveles sucesivos de CPs
        for (uint256 i = 1; i <= 10; i++) {
            uint256 cp_prev = cp_evals[i - 1];
            uint256 cp_neg_prev = cp_neg_evals[i - 1];
            uint256 cp_current = cp_evals[i];

            // Verificar que cp(i) es correcto
            if ((cp_prev + cp_neg_prev) % PRIME != cp_current) {
                return false;
            }

            // Verificar que la evaluación de x en cp(i) es acorde al root del árbol de Merkle de cp(i)
            if (!verifyMerklePath(bytes32(cp_current), cp_paths[i], cpRoots[i])) {
                return false;
            }

            // Verificar que la evaluación de -x en cp(i) es acorde al root del árbol de Merkle de cp(i)
            if (!verifyMerklePath(bytes32(cp_neg_evals[i]), cp_neg_paths[i], cpRoots[i])) {
                return false;
            }
        }

        return true;
    }
}
