# The Tavern Contract

Steps

1. Create a folder on your device and enter the folder
```
mkdir theTavern
cd theTavern
```
2. Clone this repo on to your folder.
```
git clone https://github.com/TheEgoVerse/TheTavern .
```
3. Download dependencies
```
yarn 
OR
npm install
```
4. Create .env file and copy content from .env.example folder
5. Update RPC_URL in the .env file
6. Get some TestNet Tokens from Faucets if needed  
7. Copy PRIVATE_KEY to the .env file
8. Get ETHERSCAN_API_KEY or SNOWTRACE_API_KEY
```
Go to https://etherscan.io/ or https://snowtrace.io
Create an Account and Login to your Account
Click on your Name to open a Drop down menu > Select API KEYS
Create New API Key and Paste the API KEY under ETHERSCAN_API_KEY in .env file.
```
9. General Commands
```
yarn hardhat compile - to compile your smart contract
yarn hardhat test - to execute tests of the smart contract
yarn hardhat node - to start persistent hardhat environment 

yarn hardhat run scripts/* - execute all scripts under scripts folder.
yarn hardhat run scripts/sample.ts - execute script in smaple.ts in the scripts folder.

yarn hardhat deploy - executes all scripts in deploy folder to hardhat network
yarn hardhat deploy --network localhost - executes all scripts in deploy folder to persistent hardhat network
yarn hardhat deploy --network localhost --tags all - executes all scripts in deploy folder with tag "all" to persistent hardhat network
yarn hardhat deploy --network goerli - executes all scripts in deploy folder to goerli network

```


