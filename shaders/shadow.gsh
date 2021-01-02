#include "version.glsl"

layout(triangles) in;
layout(points, max_vertices = 1) out;

uniform sampler2D tex; //I think this is the shadow buffer

#include "lighting/includes.glsl"
#include "lighting/voxelization.glsl"
#include "lighting/rt_conversion.glsl"

in vec3 positionPS[];
in vec3 normalWS[];
in vec4 color[];
in int blockId[];

out vec4 shadowMapData;

//Voxelization
void main() {
    //Don't store entities
    if(blockId[0] + blockId[1] + blockId[2] == 0) return;

    vec3 triangleCenter = (positionPS[0] + positionPS[1] + positionPS[2]) / 3.0;
    vec3 inVoxelCoord = triangleCenter - normalWS[0] * 0.1;

    vec3 voxelPosition = playerToVoxelSpace(inVoxelCoord);

    if(voxelOutOfBounds(voxelPosition)) return;

    vec2 texturePosition = voxelToTextureSpace(uvec3(voxelPosition));

    shadowMapData = vec4(color[0].rgb, 0.0);

    gl_Position = vec4(((texturePosition + 0.5) / shadowMapResolution) * 2.0 - 1.0, 0.0, 1.0);
    EmitVertex();
}
