import dotenv from "dotenv";
import {HardhatNetworkAccountUserConfig} from "hardhat/src/types/config";

dotenv.config();

export const getPKs = () => {
    let deployerAccount;

    // PKs without `0x` prefix
    if (process.env.DEPLOYER_PK) deployerAccount = process.env.DEPLOYER_PK;

    return [deployerAccount].filter(pk => !!pk);
};

export const buildHardhatNetworkAccounts = accounts => {
    const hardhatAccounts = accounts.map(pk => {
        // hardhat network wants 0x prefix in front of PK
        const accountConfig: HardhatNetworkAccountUserConfig = {
            privateKey: pk,
            balance: "1000000000000000000000000",
        };
        return accountConfig;
    });
    return hardhatAccounts;
};