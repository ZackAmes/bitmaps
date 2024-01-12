import { useComponentValue } from "@dojoengine/react";
import { Entity, getComponentValue } from "@dojoengine/recs";
import { useDojo } from "./DojoContext";
import { getEntityIdFromKeys } from "@dojoengine/utils";
import Basic from "./shaders/basic";
import { vec3 } from "three/examples/jsm/nodes/Nodes";

function App() {
    const {
        setup: {
            systemCalls: { spawn },
            components: { Moves},
        },
        account: {
            create,
            list,
            select,
            account,
            isDeploying,
            clear,
        },
    } = useDojo();

    
    // entity id we are syncing
    const entityId = getEntityIdFromKeys([BigInt(account.address)]) as Entity;

    const moves = getComponentValue(Moves, entityId);
    console.log(moves);

    let {a, b, c} = {a:0,b:0,c:0};
    let color = vec3(a/255,b/255,c/255);

    return (
        <>
            <Basic color={color}/>
        </>
    );
}

export default App;
