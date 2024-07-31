// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract StarkVerifier {
    bytes32 public merkleRoot;
    bytes32[] public cpRoots;

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
}
