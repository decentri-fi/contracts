import hardhat, {ethers} from "hardhat";

async function main() {

    // console.log('compiling');
    // await hardhat.run("compile");
    //
    // console.log("Deploying:", "MerkleProofHelper");
    //
    // const Helper = await ethers.getContractFactory("MerkleProofHelper")
    //
    // const helper = await Helper.deploy()
    // await helper.deployed();
    //
    // console.log("Helper:", helper.address);
    // console.log("Running post deployment");

    await hardhat.run("verify:verify",  {
        address: "0x7df89515bc267f1c428613334782b57b08620eea",
        constructorArguments: []
    });
}

main().then(
    () => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
