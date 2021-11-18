import hardhat, {ethers} from "hardhat";

const treasury = "0x5018365B1B7262970812cc4cdFbA7210486BD833";

async function main() {

    console.log('compiling');
    await hardhat.run("compile");

    const YeetInSushiMatic = await ethers.getContractFactory("YeetInSushi")

    console.log("Deploying:", "YeetInSushi");

    const YeetSushiArguments = [
        50,
        treasury,
        "0xc35dadb65012ec5796536bd9864ed8773abc74c4",
        "0x1b02da8cb0d097eb8d57a175b88c7d8b47997506"
    ]
    // //
    // // const yeetQS = await YeetInSushiMatic.deploy(
    // //     ...YeetSushiArguments
    // // )
    // // await yeetQS.deployed();
    //
    // console.log("YeetQS:", yeetQS.address);
    // console.log("Running post deployment");

    await hardhat.run("verify:verify",  {
        address: "0x9f5dC6B0517e7A9f22699FeE4ed652318193c0c8",
        constructorArguments: YeetSushiArguments
    });
}

main().then(
    () => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
