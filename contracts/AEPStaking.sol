// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IRewardToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

interface AEPNFT is IERC721 {
    enum TIER {
        HUMAN,
        ZOMBIE,
        VAMPIRE
    }

    function tokenTierIndex(uint256 id) external view returns (uint256, TIER);
}

contract AEPStaking is Ownable, Pausable {
    IRewardToken public preyContract;
    AEPNFT public nft;

    uint256 public stakedTotal;
    uint256 public stakingStartTime;
    uint256 public constant stakingTime = 10 minutes;
    uint256[] public rewards = [10e18, 1025e16, 1050e16]; // human , zombie, vampire rewards

    struct StakedNFT {
        uint256 tokenStakingCoolDown;
        uint256 balance;
        uint256 rewardsReleased;
    }

    constructor(AEPNFT _nft, IRewardToken _preyContract) {
        nft = _nft;
        preyContract = _preyContract;
    }

    /// @notice mapping of a tokenID to its staking info
    mapping(uint256 => StakedNFT) public stakedNFTs;

    bool public tokensClaimable;
    bool initialised;

    /// @notice event emitted when a user has staked a nft
    event Staked(address owner, uint256 tokenId);

    /// @notice event emitted when a user has unstaked a nft
    event Unstaked(address owner, uint256 tokenId);

    /// @notice event emitted when a user claims reward
    event RewardPaid(address indexed user, uint256 reward);

    /// @notice Allows reward tokens to be claimed
    event ClaimableStatusUpdated(bool status);

    /// @notice Allows reward tokens to be claimed
    event PausedStatusUpdated(bool status);

    function initStaking() public onlyOwner {
        //needs access control
        require(!initialised, "Already initialised");
        stakingStartTime = block.timestamp;
        initialised = true;
    }

    function setTokensClaimable(bool _enabled) public onlyOwner {
        //needs access control
        tokensClaimable = _enabled;
        emit ClaimableStatusUpdated(_enabled);
    }

    function pause() public onlyOwner {
        _pause();
        emit PausedStatusUpdated(true);
    }

    function unpause() public onlyOwner {
        _unpause();
        emit PausedStatusUpdated(false);
    }

    function stake(uint256 tokenId) public whenNotPaused {
        _stake(tokenId);
    }

    function stakeBatch(uint256[] memory tokenIds) public whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(tokenIds[i]);
        }
    }

    function unstake(uint256 _tokenId) public {
        uint256[] memory wrapped = new uint256[](1);
        wrapped[0] = _tokenId;
        claimReward(wrapped);
        _unstake(_tokenId);
    }

    function unstakeBatch(uint256[] memory tokenIds) public {
        claimReward(tokenIds);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (nft.ownerOf(tokenIds[i]) == msg.sender) {
                _unstake(tokenIds[i]);
            }
        }
    }

    function _stake(uint256 _tokenId) internal {
        require(initialised, "Staking System: the staking has not started");
        require(nft.ownerOf(_tokenId) == msg.sender, "user must be the owner of the token");
        StakedNFT storage stakedNFT = stakedNFTs[_tokenId];

        stakedNFT.tokenStakingCoolDown = block.timestamp;

        emit Staked(msg.sender, _tokenId);
        stakedTotal++;
    }

    function _unstake(uint256 _tokenId) internal {
        require(initialised, "Staking System: the staking has not started");
        require(nft.ownerOf(_tokenId) == msg.sender, "user must be the owner of the token");
        if (stakedNFTs[_tokenId].tokenStakingCoolDown > 0) {
            delete stakedNFTs[_tokenId];
            emit Unstaked(msg.sender, _tokenId);
            stakedTotal--;
        }
    }

    function calculateReward(uint256[] memory _tokenIds) public view returns (uint256) {
        uint256 reward = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            StakedNFT storage stakedNFT = stakedNFTs[_tokenIds[i]];
            if (
                stakedNFT.tokenStakingCoolDown < block.timestamp + stakingTime &&
                stakedNFT.tokenStakingCoolDown > 0
            ) {
                (, AEPNFT.TIER tokenTier) = getTokenTierIndex(_tokenIds[i]);
                uint256 tierIndex = uint256(tokenTier);
                uint256 tierReward = rewards[tierIndex];
                uint256 stakedDays = ((block.timestamp - uint(stakedNFT.tokenStakingCoolDown))) /
                    stakingTime;

                reward += tierReward * stakedDays;
            }
        }
        return reward;
    }

    function _updateReward(uint256[] memory _tokenIds) internal {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            StakedNFT storage stakedNFT = stakedNFTs[_tokenIds[i]];
            if (
                stakedNFT.tokenStakingCoolDown < block.timestamp + stakingTime &&
                stakedNFT.tokenStakingCoolDown > 0
            ) {
                (, AEPNFT.TIER tokenTier) = getTokenTierIndex(_tokenIds[i]);
                uint256 tierIndex = uint256(tokenTier);
                uint256 tierReward = rewards[tierIndex];
                uint256 stakedDays = ((block.timestamp - uint(stakedNFT.tokenStakingCoolDown))) /
                    stakingTime;
                uint256 partialTime = ((block.timestamp - uint(stakedNFT.tokenStakingCoolDown))) %
                    stakingTime;

                stakedNFT.balance += tierReward * stakedDays;

                stakedNFT.tokenStakingCoolDown = block.timestamp + partialTime;
            }
        }
    }

    function claimReward(uint256[] memory _tokenIds) public whenNotPaused {
        require(tokensClaimable == true, "Tokens cannnot be claimed yet");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                nft.ownerOf(_tokenIds[i]) == msg.sender,
                "You can only claim rewards for NFTs you own!"
            );
        }

        _updateReward(_tokenIds);

        uint256 reward = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            StakedNFT storage stakedNFT = stakedNFTs[_tokenIds[i]];
            reward += stakedNFT.balance;
            stakedNFT.rewardsReleased += stakedNFT.balance;
            stakedNFT.balance = 0;
        }

        if (reward > 0) {
            preyContract.mint(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function getTokenTierIndex(
        uint256 _id
    ) public view returns (uint256 tokenIndex, AEPNFT.TIER tokenTier) {
        return (nft.tokenTierIndex(_id));
    }
}
