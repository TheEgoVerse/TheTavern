// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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

error Tavern__GameLost();

contract Tavern is Ownable, Pausable, ReentrancyGuard {
    struct BoostedNFT {
        uint256 tokenBoostingCoolDown;
        uint256 rewardEarnedInBoost;
        uint256 rewardReleasedInBoost;
        uint256 totalBoosts;
        uint256 totalRewardEarned;
        uint256 totalRewardReleased;
    }

    IRewardToken public preyContract;
    AEPNFT public nft;

    uint256 public totalBoostedNFTs;
    uint256 public totalBoosts;
    uint256 public boostStartTime;
    address public teamAddress;
    uint256 public constant MAX_BOOST_COUNT = 5;
    uint256[] public rewards = [2500e15, 3075e15, 4200e15];
    uint256[] public MAXREWARD_PER_BOOST = [12500e15, 15375e15, 21000e15];
    uint256 public boostInterval = 24 hours;
    mapping(uint256 => BoostedNFT) public boostedNFTs;
    bool public initialised;

    constructor(AEPNFT _nft, IRewardToken _preyContract, address _address) {
        nft = _nft;
        preyContract = _preyContract;
        teamAddress = _address;
    }

    event Boosted(address indexed owner, uint256 indexed tokenId, uint256 indexed boostCount);

    event RewardPaid(address indexed user, uint256 indexed reward);

    event PausedStatusUpdated(bool status);

    event GameResult(address player, bool win);

    function initBoosting() public onlyOwner {
        require(!initialised, "Already initialised");
        boostStartTime = block.timestamp;
        initialised = true;
    }

    function pause() public onlyOwner {
        _pause();
        emit PausedStatusUpdated(true);
    }

    function unpause() public onlyOwner {
        _unpause();
        emit PausedStatusUpdated(false);
    }

    function boost(uint256 tokenId) public whenNotPaused nonReentrant {
        if (generateGameResult()) {
            _boost(tokenId);
            emit GameResult(msg.sender, true);
        } else {
            revert Tavern__GameLost();
        }
    }

    // function boostBatch(uint256[] memory tokenIds) public whenNotPaused nonReentrant {
    //     for (uint256 i = 0; i < tokenIds.length; i++) {
    //         _boost(tokenIds[i]);
    //     }
    // }

    function _boost(uint256 _tokenId) internal {
        require(initialised, "Boosting System: the boosting has not started");
        require(nft.ownerOf(_tokenId) == msg.sender, "User must be the owner of the token");
        BoostedNFT storage boostedNFT = boostedNFTs[_tokenId];
        require(boostedNFT.totalBoosts < 5, "Max Boosts Reached");
        if (boostedNFT.tokenBoostingCoolDown > 0) {
            require(
                boostedNFT.tokenBoostingCoolDown + 5 * boostInterval < block.timestamp,
                "Boost is Already Active"
            );
            uint256[] memory tokenList = new uint[](1);
            tokenList[0] = _tokenId;
            claimReward(tokenList);
        }
        preyContract.burn(msg.sender, 9000000000000000000);
        preyContract.mint(teamAddress, 4500000000000000000);
        boostedNFT.totalRewardEarned += boostedNFT.rewardEarnedInBoost;
        boostedNFT.totalRewardReleased += boostedNFT.rewardReleasedInBoost;
        boostedNFT.rewardEarnedInBoost = 0;
        boostedNFT.rewardReleasedInBoost = 0;
        boostedNFT.tokenBoostingCoolDown = block.timestamp;
        boostedNFT.totalBoosts = boostedNFT.totalBoosts + 1;
        totalBoostedNFTs = boostedNFT.totalBoosts == 1 ? totalBoostedNFTs + 1 : totalBoostedNFTs;
        totalBoosts = totalBoosts + 1;
        emit Boosted(msg.sender, _tokenId, boostedNFT.totalBoosts);
    }

    function calculateReward(uint256[] memory _tokenIds) public view returns (uint256) {
        uint256 claimableReward = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            BoostedNFT storage boostedNFT = boostedNFTs[_tokenIds[i]];
            if (
                boostedNFT.tokenBoostingCoolDown < block.timestamp + boostInterval &&
                boostedNFT.tokenBoostingCoolDown > 0
            ) {
                (, AEPNFT.TIER tokenTier) = getTokenTierIndex(_tokenIds[i]);
                uint256 tierIndex = uint256(tokenTier);
                uint256 tierReward = rewards[tierIndex]; // 2.5 Token
                uint256 maxTierReward = MAXREWARD_PER_BOOST[tierIndex];
                uint256 totalRewardEarned = 0;

                uint256 boostedDays = ((block.timestamp - uint(boostedNFT.tokenBoostingCoolDown))) /
                    boostInterval;
                if (tierReward * boostedDays >= maxTierReward) {
                    totalRewardEarned = maxTierReward;
                } else {
                    totalRewardEarned = tierReward * boostedDays;
                }
                claimableReward += totalRewardEarned - boostedNFT.rewardReleasedInBoost;
            }
        }
        return claimableReward;
    }

    function _updateReward(uint256[] memory _tokenIds) internal {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            BoostedNFT storage boostedNFT = boostedNFTs[_tokenIds[i]];
            if (
                boostedNFT.tokenBoostingCoolDown < block.timestamp + boostInterval &&
                boostedNFT.tokenBoostingCoolDown > 0
            ) {
                (, AEPNFT.TIER tokenTier) = getTokenTierIndex(_tokenIds[i]);
                uint256 tierIndex = uint256(tokenTier);
                uint256 tierReward = rewards[tierIndex];
                uint256 maxTierReward = MAXREWARD_PER_BOOST[tierIndex];

                uint256 boostedDays = ((block.timestamp - uint(boostedNFT.tokenBoostingCoolDown))) /
                    boostInterval;
                if (tierReward * boostedDays >= maxTierReward) {
                    boostedNFT.rewardEarnedInBoost = maxTierReward;
                } else {
                    boostedNFT.rewardEarnedInBoost = tierReward * boostedDays;
                }
            }
        }
    }

    function claimReward(uint256[] memory _tokenIds) public whenNotPaused {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                nft.ownerOf(_tokenIds[i]) == msg.sender,
                "You can only claim rewards for NFTs you own!"
            );
        }

        _updateReward(_tokenIds);

        uint256 reward = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            BoostedNFT storage boostedNFT = boostedNFTs[_tokenIds[i]];
            reward += boostedNFT.rewardEarnedInBoost - boostedNFT.rewardReleasedInBoost;
            boostedNFT.rewardReleasedInBoost = boostedNFT.rewardEarnedInBoost;
        }

        if (reward > 0) {
            preyContract.mint(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function updateBoostInterval(uint256 hoursCount) external onlyOwner {
        boostInterval = hoursCount * 1 hours;
    }

    function getTokenTierIndex(
        uint256 _id
    ) public view returns (uint256 tokenIndex, AEPNFT.TIER tokenTier) {
        return (nft.tokenTierIndex(_id));
    }

    function generateGameResult() private view returns (bool) {
        uint256 entropy = uint256(
            keccak256(abi.encodePacked(msg.sender, block.timestamp, tx.origin))
        );
        uint256 score = (entropy % 100) + 1;
        return score > 67;
    }
}
