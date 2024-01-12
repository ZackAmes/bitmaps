import { getComponentValue } from "@dojoengine/recs";
import { getEntityIdFromKeys } from "@dojoengine/utils";
import { shortString } from "starknet";

export const getShader = (manager: any, vertex_length: number, frag_length:number) => {
    let vertex_shader = "";
    let frag_shader = "";


    for(let i = 0; i < vertex_length; i++) {
        let vertex_manager_id = getEntityIdFromKeys([BigInt(0), BigInt(i)])
        let value = getComponentValue(manager, vertex_manager_id)
        console.log(value)
        let string = value ? shortString.decodeShortString(value.value) : ""
        console.log(string)
        vertex_shader += string;
    }
    for(let i = 0; i < frag_length; i++) {
        let frag_manager_id = getEntityIdFromKeys([BigInt(1), BigInt(i)])
        let value = getComponentValue(manager, frag_manager_id)
        let string = value ? shortString.decodeShortString(value.value) : ""
        frag_shader += string;
    }



    return {vertex_shader, frag_shader}

}

