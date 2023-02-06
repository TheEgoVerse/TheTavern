// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IRewardToken is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;
}

interface AEPNFT is IERC721 {
    enum TIER {
        HUMAN,
        ZOMBIE,
        VAMPIRE
    }

    function tokenTierIndex(uint256 id) external view returns (uint256, TIER);
}

contract Tavern is Ownable, Pausable {
    IRewardToken public preyContract;
    AEPNFT public nft;

    uint256 public totalBoostedNFTs;
    uint256 public totalBoosts;
    uint256 public stakingStartTime;
    address public OwnerAddress;
    uint256 public constant stakingTime = 2 minutes;
    uint256 public constant MAX_BOOST_COUNT = 5;
    uint256[] public rewards = [2500e15, 3075e15, 4200e15];
    uint256[] public MAXREWARD_PER_BOOST = [12500e15, 15375e15, 21000e15];

    struct StakedNFT {
        uint256 tokenStakingCoolDown;
        uint256 rewardEarnedInBoost;
        uint256 rewardReleasedInBoost;
        uint256 totalBoosts;
        uint256 totalRewardEarned;
        uint256 totalRewardReleased;
    }

    constructor(AEPNFT _nft, IRewardToken _preyContract, address ownerAddress) {
        nft = _nft;
        preyContract = _preyContract;
        OwnerAddress = ownerAddress;
    }

    mapping(uint256 => StakedNFT) public stakedNFTs;

    bool public tokensClaimable;
    bool initialised;

    function initStaking() public onlyOwner {
        require(!initialised, "Already initialised");
        stakingStartTime = block.timestamp;
        initialised = true;
    }

    function setTokensClaimable(bool _enabled) public onlyOwner {
        tokensClaimable = _enabled;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function boost(uint256 tokenId, uint256 amount) public whenNotPaused {
        _boost(tokenId, amount);
    }

    // function boostBatch(uint256[] memory tokenIds) public whenNotPaused {
    //     for (uint256 i = 0; i < tokenIds.length; i++) {
    //         _stake(tokenIds[i]);
    //     }
    // }

    function _boost(uint256 _tokenId, uint256 _amount) internal {
        require(initialised, "Staking System: the staking has not started");
        require(nft.ownerOf(_tokenId) == msg.sender, "user must be the owner of the token");
        StakedNFT storage stakedNFT = stakedNFTs[_tokenId];
        require(stakedNFT.totalBoosts < 5, "Max Boosts Reached");
        if (stakedNFT.tokenStakingCoolDown > 0) {
            require(
                stakedNFT.tokenStakingCoolDown + 5 * stakingTime < block.timestamp,
                "Boost is Already Active"
            );
        }
        require(_amount >= 9_000_000_000_000_000_000, "Invalid Amount");
        preyContract.burn(msg.sender, 9000000000000000000); // Burn 4.5 $PREY Tokens
        preyContract.mint(OwnerAddress, 4500000000000000000); // Transfer 4.5 $PREY Tokens
        claimReward(_tokenId);
        stakedNFT.totalRewardEarned += stakedNFT.rewardEarnedInBoost;
        stakedNFT.totalRewardReleased += stakedNFT.rewardReleasedInBoost;
        stakedNFT.rewardEarnedInBoost = 0;
        stakedNFT.rewardReleasedInBoost = 0;
        stakedNFT.tokenStakingCoolDown = block.timestamp;
        stakedNFT.totalBoosts = stakedNFT.totalBoosts + 1;
        totalBoostedNFTs = stakedNFT.totalBoosts == 1 ? totalBoostedNFTs + 1 : totalBoostedNFTs;
        totalBoosts = totalBoosts + 1;
    }

    function getTokenTierIndex(
        uint256 _id
    ) public view returns (uint256 tokenIndex, AEPNFT.TIER tokenTier) {
        return (nft.tokenTierIndex(_id));
    }

    function calculateReward(uint256 _tokenId) public view returns (uint256) {
        uint256 claimableReward = 0;
        // for (uint256 i = 0; i < _tokenIds.length; i++) {
        StakedNFT storage stakedNFT = stakedNFTs[_tokenId];
        if (
            stakedNFT.tokenStakingCoolDown < block.timestamp + stakingTime &&
            stakedNFT.tokenStakingCoolDown > 0
        ) {
            (, AEPNFT.TIER tokenTier) = getTokenTierIndex(_tokenId);
            uint256 tierIndex = uint256(tokenTier);
            uint256 tierReward = rewards[tierIndex]; // 2.5 Token
            uint256 maxTierReward = MAXREWARD_PER_BOOST[tierIndex];
            uint256 totalRewardEarned = 0;

            uint256 stakedDays = ((block.timestamp - uint(stakedNFT.tokenStakingCoolDown))) /
                stakingTime; // Total Days Staked
            // stakedDays = stakedDays < BOOST_DURATION ? stakedDays : BOOST_DURATION; // // Needs improvement
            if (tierReward * stakedDays >= maxTierReward) {
                totalRewardEarned = maxTierReward;
            } else {
                totalRewardEarned = tierReward * stakedDays;
            }
            claimableReward += totalRewardEarned - stakedNFT.rewardReleasedInBoost;
        }
        // }
        return claimableReward;
    }

    function _updateReward(uint256 _tokenId) internal {
        StakedNFT storage stakedNFT = stakedNFTs[_tokenId];
        if (
            stakedNFT.tokenStakingCoolDown < block.timestamp + stakingTime &&
            stakedNFT.tokenStakingCoolDown > 0
        ) {
            (, AEPNFT.TIER tokenTier) = getTokenTierIndex(_tokenId);
            uint256 tierIndex = uint256(tokenTier);
            uint256 tierReward = rewards[tierIndex];
            uint256 maxTierReward = MAXREWARD_PER_BOOST[tierIndex];

            uint256 stakedDays = ((block.timestamp - uint(stakedNFT.tokenStakingCoolDown))) /
                stakingTime;
            if (tierReward * stakedDays >= maxTierReward) {
                stakedNFT.rewardEarnedInBoost = maxTierReward;
            } else {
                stakedNFT.rewardEarnedInBoost = tierReward * stakedDays;
            }
        }
    }

    function claimReward(uint256 _tokenId) public whenNotPaused {
        require(tokensClaimable == true, "Tokens cannnot be claimed yet");

        // for (uint256 i = 0; i < _tokenIds.length; i++) {
        require(
            nft.ownerOf(_tokenId) == msg.sender,
            "You can only claim rewards for NFTs you own!"
        );
        // }

        _updateReward(_tokenId);

        uint256 reward = 0;
        // for (uint256 i = 0; i < _tokenIds.length; i++) {
        StakedNFT storage stakedNFT = stakedNFTs[_tokenId];
        reward += stakedNFT.rewardEarnedInBoost - stakedNFT.rewardReleasedInBoost;
        stakedNFT.rewardReleasedInBoost = stakedNFT.rewardEarnedInBoost;
        // stakedNFT.balance = 0;
        // }

        if (reward > 0) {
            preyContract.mint(msg.sender, reward);
        }
    }
}
