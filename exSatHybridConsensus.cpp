// exSatHybridConsensus.cpp
// Simplified Prototype for Hybrid PoW + PoS Consensus with Metadata Extension on Bitcoin Fork
// 

#include <iostream>
#include <map>
#include <vector>
#include <string>
#include <ctime>
#include <random>

struct Block {
    int index;
    std::string previousHash;
    std::string hash;
    std::string metadata; // exSat extended metadata (e.g., identity, tokens)
    time_t timestamp;
    uint64_t nonce;
    double stakeWeight; // PoS weight
    bool isPoW;
};

std::vector<Block> blockchain;
std::map<std::string, double> stakes; // walletAddress -> staked amount

// Simulate PoW hash function
std::string generatePoWHash(int index, const std::string& previousHash, const std::string& metadata, uint64_t nonce) {
    return std::to_string(index) + previousHash + metadata + std::to_string(nonce);
}

// Check hybrid consensus condition
bool validateConsensus(const Block& newBlock) {
    // Simulate hybrid rule: at least 60% blocks are PoW, 40% PoS
    int powCount = 0;
    int posCount = 0;
    for (const auto& block : blockchain) {
        if (block.isPoW) powCount++;
        else posCount++;
    }

    double total = powCount + posCount + 1;
    double powRatio = (double)(powCount + (newBlock.isPoW ? 1 : 0)) / total;
    double posRatio = (double)(posCount + (!newBlock.isPoW ? 1 : 0)) / total;

    return powRatio >= 0.5 && posRatio >= 0.3;
}

// PoS block generation
Block generatePoSBlock(const std::string& previousHash, const std::string& metadata, const std::string& stakerAddress) {
    Block block;
    block.index = blockchain.size();
    block.previousHash = previousHash;
    block.metadata = metadata;
    block.timestamp = time(nullptr);
    block.stakeWeight = stakes[stakerAddress];
    block.isPoW = false;
    block.nonce = 0;
    block.hash = generatePoWHash(block.index, previousHash, metadata, block.nonce);
    return block;
}

// PoW block mining
Block minePoWBlock(const std::string& previousHash, const std::string& metadata) {
    Block block;
    block.index = blockchain.size();
    block.previousHash = previousHash;
    block.metadata = metadata;
    block.timestamp = time(nullptr);
    block.isPoW = true;
    block.nonce = 0;

    // Simulated PoW
    while (true) {
        block.hash = generatePoWHash(block.index, previousHash, metadata, block.nonce);
        if (block.hash.substr(0, 2) == "00") break; // Simulated difficulty
        block.nonce++;
    }
    return block;
}

// Add block to blockchain after hybrid validation
bool addBlockToChain(const Block& block) {
    if (validateConsensus(block)) {
        blockchain.push_back(block);
        std::cout << "Block #" << block.index << " added. Type: " << (block.isPoW ? "PoW" : "PoS") << "\n";
        return true;
    } else {
        std::cout << "Block #" << block.index << " rejected. Hybrid consensus not satisfied.\n";
        return false;
    }
}

int main() {
    // Genesis Block
    Block genesis;
    genesis.index = 0;
    genesis.previousHash = "0";
    genesis.metadata = "Genesis Metadata";
    genesis.timestamp = time(nullptr);
    genesis.nonce = 0;
    genesis.hash = generatePoWHash(0, "0", "Genesis Metadata", 0);
    genesis.isPoW = true;
    blockchain.push_back(genesis);

    // Simulate stakes
    stakes["wallet1"] = 100.0;
    stakes["wallet2"] = 50.0;

    // Add PoW block
    Block powBlock = minePoWBlock(genesis.hash, "PoW block with exSat metadata");
    addBlockToChain(powBlock);

    // Add PoS block
    Block posBlock = generatePoSBlock(powBlock.hash, "PoS block with exSat ID tag", "wallet1");
    addBlockToChain(posBlock);

    return 0;
}
