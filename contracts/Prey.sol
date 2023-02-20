// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Prey is ERC20, ERC20Snapshot, Ownable, Pausable {
    using SafeMath for uint256;

    string private constant _name = "EgoVerse";
    string private constant _symbol = "Prey";
    uint256 public constant _OnePrey = 1e18; //Decimals
    uint256 public totalMinted = 0;
    uint256 public totalBurned = 0;
    address public AirdropAddress; // Find out this address
    address public StakingAddress; // AEP Staking Contract Address
    address public BreedingAddress; // Find out this address
    address public GameAddress; // Is Empty for Now
    address public ExtensionAddress; // Is Empty for Now

    // Current Token Balance    = 000_175_000_000_000_000_000_000
    // Total Burned             = 523_200_000_000_000_000_000_000
    // Total Supply             = 412_969_250_000_000_000_000_000
    // Total Minted             = 936_069_250_000_000_000_000_000

    /* events */
    event Burned(address _from, uint256 _amount);
    event Minted(address _to, uint256 _amount);
    event TransferSent(address _from, address _to, uint256 _amount);

    constructor() ERC20(_name, _symbol) {
        //inital value
        _mint(address(this), SafeMath.mul(100, _OnePrey)); // Mint 100 PREY Tokens
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Can be called by one of the 5 Defined Addresses
    function mint(address _to, uint256 _amount) external whenNotPaused {
        require(_to != address(0), "address is not correct");
        require(
            StakingAddress != address(0) ||
                BreedingAddress != address(0) ||
                GameAddress != address(0) ||
                ExtensionAddress != address(0) ||
                AirdropAddress != address(0),
            "contracts addresses is not set or not correct"
        );
        require(
            _msgSender() == StakingAddress ||
                _msgSender() == BreedingAddress ||
                _msgSender() == GameAddress ||
                _msgSender() == ExtensionAddress ||
                _msgSender() == AirdropAddress,
            "sender does not have permission"
        );
        totalMinted = SafeMath.add(totalMinted, _amount);
        _mint(_to, _amount);
        emit Minted(_to, _amount);
    }

    // Can be called by one of the 4 Defined Addresses
    function burn(address _from, uint256 _amount) external whenNotPaused {
        require(_from != address(0), "address is not correct");
        require(
            StakingAddress != address(0) ||
                BreedingAddress != address(0) ||
                GameAddress != address(0) ||
                ExtensionAddress != address(0),
            "contracts addresses is not set or not correct"
        );
        require(
            _msgSender() == StakingAddress ||
                _msgSender() == BreedingAddress ||
                _msgSender() == GameAddress ||
                _msgSender() == ExtensionAddress,
            "sender does not have permission"
        );
        totalBurned = SafeMath.add(totalBurned, _amount);
        _burn(_from, _amount);
        emit Burned(_from, _amount);
    }

    // Transfer tokens held by the contract to an address
    function transferTokens(address to, uint256 amount) external onlyOwner {
        require(amount <= totalBalance(), "transfer amount exceeds balance");
        address token = address(this);
        _transfer(token, to, amount);
        emit TransferSent(msg.sender, to, amount);
    }

    // Transfer tokens held by the contract to an address
    function transferPrey(address to, uint256 amount) external onlyOwner {
        require(amount <= totalBalance(), "transfer amount exceeds balance");
        address token = address(this);
        uint256 preyAmount = SafeMath.mul(amount, _OnePrey);
        _transfer(token, to, preyAmount);
        emit TransferSent(msg.sender, to, preyAmount);
    }

    function setAirdropAddress(address _airdropAddress) external onlyOwner {
        require(_airdropAddress != address(0), "address is not correct");
        AirdropAddress = _airdropAddress;
    }

    function setStakingAddress(address _stakingAddress) external onlyOwner {
        require(_stakingAddress != address(0), "address is not correct");
        StakingAddress = _stakingAddress;
    }

    function setBreedingAddress(address _breedingAddress) external onlyOwner {
        require(_breedingAddress != address(0), "address is not correct");
        BreedingAddress = _breedingAddress;
    }

    function setGameAddress(address _gameAddress) external onlyOwner {
        require(_gameAddress != address(0), "address is not correct");
        GameAddress = _gameAddress;
    }

    //for further project contract development
    function setExtensionAddress(address _extensionAddress) external onlyOwner {
        require(_extensionAddress != address(0), "address is not correct");
        ExtensionAddress = _extensionAddress;
    }

    function totalBalance() public view returns (uint256) {
        return balanceOf(address(this));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
