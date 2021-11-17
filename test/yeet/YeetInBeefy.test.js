const {expect} = require('chai');
const { ethers } = require("hardhat");
const {BigNumber} = require("ethers");

const TIMEOUT = 10 * 60 * 100000;

const config = {
    treasury: "0x5018365B1B7262970812cc4cdFbA7210486BD833",
    yeetInQuickswap: "0xf369F7b3610FCC8886482d123aFa71CB1EA67335",
    WMATIC: "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270",

}

describe("Yeet In Beefy", () => {

    let yeetInBeefy, yeetInQuickswap, wmaticContract;

    before(async() => {
        [deployer] = await ethers.getSigners();
        yeetInQuickswap = await ethers.getContractAt("YeetInQuickswap", config.yeetInQuickswap);
        wmaticContract = await ethers.getContractAt("ERC20", config.WMATIC);
        const YeetInBeefy = await ethers.getContractFactory("YeetInBeefy");
        yeetInBeefy = await YeetInBeefy.deploy(config.treasury)
    });

    it('should correctly yeet in', async() => {

        const amount = BigNumber.from("100000000000000000");
        const mooWMATICETH = "0x8b89477dFde285849E1B07947E25012206F4D674";
        await wmaticContract.approve(yeetInBeefy.address, BigNumber.from("10000000000000000000000000000"))
        console.log('approved');
        await yeetInBeefy.PerformYeetIn(
            config.WMATIC,
            amount,
            BigNumber.from(0),
            mooWMATICETH,
            config.yeetInQuickswap
        )
    }).timeout(TIMEOUT);
});