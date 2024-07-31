// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

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
        for (uint256 i = 0; i < LARGE_DOMAIN_SIZE; i++) {
            domain[i] = modExp(GENERATOR, i, PRIME);
        }
        return domain;
    }

    function modExp(uint256 base, uint256 exp, uint256 mod) internal pure returns (uint256) {
        uint256 result = 1;
        while (exp > 0) {
            if (exp % 2 == 1) {
                result = (result * base) % mod;
            }
            base = (base * base) % mod;
            exp = exp / 2;
        }
        return result;
    }
}
