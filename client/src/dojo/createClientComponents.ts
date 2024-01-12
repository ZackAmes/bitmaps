import { overridableComponent } from "@dojoengine/recs";
import { SetupNetworkResult } from "./setupNetwork";

export type ClientComponents = ReturnType<typeof createClientComponents>;

export function createClientComponents({
    contractComponents,
}: SetupNetworkResult) {
    return {
        ...contractComponents,
        Moves: overridableComponent(contractComponents.Moves),
        Position: overridableComponent(contractComponents.Position),
        ERC721Meta: overridableComponent(contractComponents.ERC721Meta)
    };
}
