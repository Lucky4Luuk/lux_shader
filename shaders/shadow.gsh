#include "version.glsl"
#include "settings.glsl"

layout(triangles) in;
layout(points, max_vertices = LOD_LEVELS) out;

#include "lighting/includes.glsl"
#include "lighting/voxelization.glsl"
#include "lighting/rt_conversion.glsl"

in vec3 positionPS[];
in vec3 normalWS[];
in vec4 color[];
in int blockId[];
flat in vec2 midTexcoord[];
in vec2 texcoord[];

flat out vec4 shadowMapData;

//Voxelization
void main() {
    //Don't store entities
    if(blockId[0] + blockId[1] + blockId[2] == 0) return;

    vec3 triangleCenter = (positionPS[0] + positionPS[1] + positionPS[2]) / 3.0;
    vec3 inVoxelCoord = triangleCenter - normalWS[0] * 0.01;

    vec3 voxelPosition = playerToVoxelSpace(inVoxelCoord);

    if(voxelOutOfBounds(voxelPosition)) return;

    // vec2 atlasUV = texcoord[0]; //TODO: Might be the wrong corner.
    // vec2 atlasUV = min(texcoord[0], min(texcoord[1], texcoord[2]));
    vec2 atlasUV = midTexcoord[0] - abs(midTexcoord[0] - texcoord[0]);
    float atlasUV_packed = packTexcoord(atlasUV);

    shadowMapData = vec4(color[0].rgb, 0.0); //W channel is 1.0 when there's no block, otherwise there is a block. Perhaps we can store blockID here?

    for (int lod = 0; lod < LOD_LEVELS; lod++) {
        vec2 texturePosition = voxelToTextureSpace(uvec3(voxelPosition), lod);
        gl_Position = vec4(((texturePosition + 0.5) / shadowMapResolution) * 2.0 - 1.0, atlasUV_packed, 1.0);
        EmitVertex();
    }
}
