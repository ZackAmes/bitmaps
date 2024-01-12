import { OrbitControls, PerspectiveCamera, Box } from '@react-three/drei'
import { MeshBasicNodeMaterial, ShaderNodeObject,mul,cond,mix,smoothstep, Node, sub,cos,add, vec3,exp, abs, positionLocal, length} from 'three/examples/jsm/nodes/Nodes.js'
import { WebGPUCanvas } from '../WebGPUCanvas.tsx'
import { FC } from 'react'

interface BasicProps {
    color: ShaderNodeObject<Node>
}

const material = new MeshBasicNodeMaterial()



const Basic: FC<BasicProps> = ({color}) => {

    const sd = (p:any, r:any) => {
        return sub(length(p), r);
    }

    let uv0 = positionLocal;
    let d = sd(uv0.xy, .5);

    let col = cond(d.greaterThan(0), color, color.zyx);
    col = col.mul(sub(1, exp(mul(-6, abs(d)))));
    col = col.mul(add( .8, mul(.2, cos(mul(150,d)))));

    col = mix( col, vec3(1.0), sub(1,smoothstep(0.0,0.01,abs(d))) );

    material.colorNode = col
    return (
        <WebGPUCanvas>

                <mesh >
                    <planeGeometry args={[3,3]}/>
                    <primitive attach="material" object={material} />
                </mesh>

            <OrbitControls />
            <PerspectiveCamera position={[2, 3, 4]} makeDefault />
        </WebGPUCanvas>
    )
}

export default Basic;