import hardhat, {ethers} from "hardhat";

const treasury = "0x5018365B1B7262970812cc4cdFbA7210486BD833";

async function main() {

    console.log('compiling');
    await hardhat.run("compile");

    const yeet = await ethers.getContractAt("YeetInBeefy", "0x862EdCec8bD1e356b3923fd8Ebf7Ac38da4418B1")

    console.log("Deploying:", "YeetInBeefy");

    const YIBArguments = [
        treasury
    ]
    //
    // const yeet = await YeetInBeefy.deploy(
    //     ...YIBArguments
    // )
    // await yeet.deployed();

    console.log("YeetQS:", yeet.address);
    console.log("Running post deployment");

    await hardhat.run("verify:verify",  {
        address: yeet.address,
        constructorArguments: YIBArguments
    });
}

main().then(
    () => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
