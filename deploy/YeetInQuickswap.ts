import hardhat, {ethers} from "hardhat";

const treasury = "0x5018365B1B7262970812cc4cdFbA7210486BD833";

async function main() {

    console.log('compiling');
    await hardhat.run("compile");

    const YeetQuickswap = await ethers.getContractFactory("YeetInQuickswap")

    console.log("Deploying:", "YeetInQuickswap");

    const YeetQuickswapArguments = [
        50, treasury
    ]

    const yeetQS = await YeetQuickswap.deploy(
        ...YeetQuickswapArguments
    )
    await yeetQS.deployed();

    console.log("YeetQS:", yeetQS.address);
    console.log("Running post deployment");

    // await hardhat.run("verify:verify",  {
    //     address: "0x8F2aae0711014Cc21Cb1F090d6b945EDC01EED91",
    //     constructorArguments: YeetQuickswapArguments
    // });
}

main().then(
    () => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
