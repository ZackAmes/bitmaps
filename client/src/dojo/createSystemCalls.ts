import { SetupNetworkResult } from "./setupNetwork";
import { Account } from "starknet";
import { Entity, getComponentValue } from "@dojoengine/recs";
import { uuid } from "@latticexyz/utils";
import { ClientComponents } from "./createClientComponents";
import {
    getEntityIdFromKeys,
    getEvents,
    setComponentsFromEvents,
} from "@dojoengine/utils";

export type SystemCalls = ReturnType<typeof createSystemCalls>;

export function createSystemCalls(
    { execute, contractComponents }: SetupNetworkResult
) {
    const spawn = async (signer: Account) => {

        try {
            const { transaction_hash } = await execute(
                signer,
                "actions",
                "spawn",
                []
            );

            setComponentsFromEvents(
                contractComponents,
                getEvents(
                    await signer.waitForTransaction(transaction_hash, {
                        retryInterval: 100,
                    })
                )
            );
        } catch (e) {
            console.log(e);
        
        }
    };


    return {
        spawn
    };
}
