# Cuda-Blockchain-PoW

A CUDA-based implementation of the Proof of Work consensus algorithm for blockchain, optimized for finding nonces efficiently using GPU acceleration

## Overview

This project is a CUDA-based implementation of the Proof of Work consensus algorithm for blockchain. The Proof of Work algorithm is used to secure the blockchain by requiring miners to solve a computationally difficult problem in order to add a new block to the blockchain. This implementation is optimized for finding nonces efficiently using NVIDIA GPU acceleration.

The code purpose is to find a nonce that, when appended to the block data and hashed, produces a hash value that meets a certain difficulty target. The difficulty target is defined by the number of leading zeros that the hash value must have. The nonce is a 32-bit integer that is appended to the block data and hashed using the SHA-256 algorithm. The hash value is then compared to the difficulty target (in our case 5), and if it meets the target, the block is considered valid and can be added to the blockchain.

If found, the resulting block hash and the nonce will be printed in the results.csv file, along with the time taken to find the nonce.

To run: `make LOCAL=y run`

Clean: `make clean`
