#include <stdio.h>
#include <stdint.h>
#include "../include/utils.cuh"
#include <string.h>
#include <stdlib.h>
#include <inttypes.h>

__device__ void d_strcat(char *dest, const char *src) {
    int i = 0;
    while (dest[i] != '\0') {
        i++;
    }

    int j = 0;
    while (src[j] != '\0') {
        dest[i++] = src[j++];
    }

    dest[i] = '\0';
}


/**
 * @brief Function to search for all nonces from 1 through MAX_NONCE (inclusive) using CUDA Threads
 *@param prev_block_hash The hash of the previous block
*/
__global__ void findNonce(const BYTE *prev_block_hash, const BYTE *top_hash, const BYTE *difficulty, uint64_t max_nonce, BYTE *best_hash, uint64_t *best_nonce, bool *found) {
    uint64_t idx = blockIdx.x * blockDim.x + threadIdx.x + 1;

    if (idx > max_nonce || *found) {
        return;
    }

    BYTE hash[SHA256_HASH_SIZE];
    BYTE block_content[BLOCK_SIZE];
    char nonce_str[20];

    d_strcpy((char*)block_content, (const char*)prev_block_hash);
    d_strcat((char*)block_content, (const char*)top_hash);

    intToString(idx, nonce_str);

    d_strcat((char*)block_content, nonce_str);
    
    BYTE local_difficulty[SHA256_HASH_SIZE];
    memcpy(local_difficulty, difficulty, SHA256_HASH_SIZE);


    apply_sha256(block_content, d_strlen((const char*)block_content), hash, 1);

     if (compare_hashes(hash, local_difficulty) <= 0) {
        memcpy(best_hash, hash, SHA256_HASH_SIZE);
        *best_nonce = idx;
        *found = true;
    }
}


int main(int argc, char **argv) {
    BYTE hashed_tx1[SHA256_HASH_SIZE], hashed_tx2[SHA256_HASH_SIZE], hashed_tx3[SHA256_HASH_SIZE], hashed_tx4[SHA256_HASH_SIZE],
			tx12[SHA256_HASH_SIZE * 2], tx34[SHA256_HASH_SIZE * 2], hashed_tx12[SHA256_HASH_SIZE], hashed_tx34[SHA256_HASH_SIZE],
			tx1234[SHA256_HASH_SIZE * 2], top_hash[SHA256_HASH_SIZE];
    uint64_t nonce = 0, *d_best_nonce;
    BYTE *d_prev_block_hash, *d_top_hash, *d_difficulty, *d_best_hash;
    bool *d_found, found = false;
    cudaMalloc(&d_found, sizeof(bool));
    cudaMemcpy(d_found, &found, sizeof(bool), cudaMemcpyHostToDevice);

    apply_sha256(tx1, strlen((const char*)tx1), hashed_tx1, 1);
    apply_sha256(tx2, strlen((const char*)tx2), hashed_tx2, 1);
    apply_sha256(tx3, strlen((const char*)tx3), hashed_tx3, 1);
    apply_sha256(tx4, strlen((const char*)tx4), hashed_tx4, 1);

    strcpy((char *)tx12, (const char *)hashed_tx1);
    strcat((char *)tx12, (const char *)hashed_tx2);
    apply_sha256(tx12, strlen((const char*)tx12), hashed_tx12, 1);
    strcpy((char *)tx34, (const char *)hashed_tx3);
    strcat((char *)tx34, (const char *)hashed_tx4);
    apply_sha256(tx34, strlen((const char*)tx34), hashed_tx34, 1);
    strcpy((char *)tx1234, (const char *)hashed_tx12);
    strcat((char *)tx1234, (const char *)hashed_tx34);
    apply_sha256(tx1234, strlen((const char*)tx34), top_hash, 1);

    cudaMalloc(&d_prev_block_hash, SHA256_HASH_SIZE);
    cudaMalloc(&d_top_hash, SHA256_HASH_SIZE);
    cudaMalloc(&d_difficulty, SHA256_HASH_SIZE);
    cudaMalloc(&d_best_hash, SHA256_HASH_SIZE);
    cudaMalloc(&d_best_nonce, sizeof(uint64_t));

    cudaMemcpy(d_prev_block_hash, prev_block_hash, SHA256_HASH_SIZE, cudaMemcpyHostToDevice);
    cudaMemcpy(d_top_hash, top_hash, SHA256_HASH_SIZE, cudaMemcpyHostToDevice);
    cudaMemcpy(d_difficulty, difficulty_5_zeros, SHA256_HASH_SIZE, cudaMemcpyHostToDevice);
    cudaMemcpy(d_best_hash, difficulty_5_zeros, SHA256_HASH_SIZE, cudaMemcpyHostToDevice);
    cudaMemcpy(d_best_nonce, &nonce, sizeof(uint64_t), cudaMemcpyHostToDevice);

    int numBlocks = MAX_NONCE / 256;
    cudaEvent_t start, stop;
	startTiming(&start, &stop);

    findNonce<<<numBlocks, 256>>>(d_prev_block_hash, d_top_hash, d_difficulty, MAX_NONCE, d_best_hash, d_best_nonce, d_found);
    cudaDeviceSynchronize();
    float seconds = stopTiming(&start, &stop);

    cudaMemcpy(&nonce, d_best_nonce, sizeof(uint64_t), cudaMemcpyDeviceToHost);
    BYTE block_hash[SHA256_HASH_SIZE];
    cudaMemcpy(block_hash, d_best_hash, SHA256_HASH_SIZE, cudaMemcpyDeviceToHost);

    printResult(block_hash, nonce, seconds);
    cudaFree(d_prev_block_hash);
    cudaFree(d_top_hash);
    cudaFree(d_difficulty);
    cudaFree(d_best_hash);
    cudaFree(d_best_nonce);
    cudaFree(d_found);

    return 0;
}
