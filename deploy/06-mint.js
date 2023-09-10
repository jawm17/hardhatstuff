const { network, ethers } = require("hardhat")
var Contract = require('web3-eth-contract');
const usdcAbi = require("./usdcAbi.json");

module.exports = async ({ getNamedAccounts }) => {
    const { deployer } = await getNamedAccounts()
    accounts = await ethers.getSigners();
    const usdcTokenAddress = "0x07865c6E87B9F70255377e024ace6630C1Eaa37F";
    Contract.setProvider("http://localhost:31337");
    const privateKey = "db58895c10091469b28699243692fe8fa2fb5dd177675eb67c7796b5049074d1";

    const usdcContractEthers = new ethers.Contract(usdcTokenAddress, usdcAbi, ethers.provider);
    const nftContract = await ethers.getContract("Card", deployer);

    // Get the USDC balance of the specified address
    const balance = await usdcContractEthers.balanceOf("0x5E52D0Db4bf47B169339f2BfBD1cf4d14e2aA032");
    console.log(`USDC balance: ${balance.toString()}`);

    await sendUsdc(accounts[0].address, 5000000);
    const balance2 = await usdcContractEthers.balanceOf("0x5E52D0Db4bf47B169339f2BfBD1cf4d14e2aA032");
    console.log(`USDC balance: ${balance2.toString()}`);

    const mintResult = await mintNft(accounts[0].address.toString());
    console.log(mintResult);

    const tokenBal = await nftContract.getTokenBalance(0);
    console.log(tokenBal.toString());

    // await sendValue();

    const balance3 = await usdcContractEthers.balanceOf(deployer.toString());
    console.log(`USDC balance: ${(balance3 / 10 ** 6).toString()}`);

    const balanceBefore = await ethers.provider.getBalance(deployer);
    console.log((balanceBefore / 10 ** 18).toString())

    // await withdrawFees();

    // const ownerRes = await nftContract.getOwnerTest(0);
    // console.log(ownerRes);

    const simulateRes = await nftContract.simulateTx();

    // const balance4 = await usdcContractEthers.balanceOf(deployer.toString());
    // console.log(`USDC balance: ${(balance4 / 10 ** 6).toString()}`);

    const balanceAfter = await ethers.provider.getBalance(deployer);
    console.log((balanceAfter / 10 ** 18).toString());
    console.log((balanceBefore - balanceAfter / 10 ** 18).toString());




    async function sendUsdc(recipient, amount) {
        const signer = new ethers.Wallet(privateKey, ethers.provider);
        // Approve the USDC contract to spend the required amount
        const approved = await usdcContractEthers.connect(signer).approve(recipient, amount);
        // Send the USDC tokens to the recipient
        const sent = await usdcContractEthers.connect(signer).transfer(recipient, amount);
        await sent.wait(1);
        return console.log("USDC sent successfully:", sent);
    }

    async function mintNft(recipient) {
        const usdcContract = new ethers.Contract(usdcTokenAddress, usdcAbi, accounts[0]);

        const approveTx = await usdcContract.approve(nftContract.address.toString(), 100000000);
        await approveTx.wait();

        const mintTx = await nftContract.claimTo(recipient, 100000000);
        await mintTx.wait();

        return ("Approved and minted successfully!");
    }

    async function sendValue() {
        const nftContract = await ethers.getContract("Card", deployer);
        res = await nftContract.sendTokens(50, accounts[15].address.toString(), 0);
        return console.log("Successfully sent value!");
    }

    async function withdrawFees() {
        const nftContract = await ethers.getContract("Card", deployer);
        res = await nftContract.withdrawFees();
        return console.log("Successfully withdrew fees!");
    }
}
module.exports.tags = ["all", "mint"]
