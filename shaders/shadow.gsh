#include "version.glsl"
#include "settings.glsl"

layout(triangles) in;
layout(points, max_vertices = LOD_LEVELS) out;

#include "lib/includes.glsl"
#include "lib/voxelization.glsl"
#include "lib/rt_conversion.glsl"
#include "lib/blockmapping.glsl"

//Triangle flags
flat out int mode; //0 = voxel data, 1 = shadowmap data

//Voxel data
in vec3 positionPS[];
in vec3 normalWS[];
in vec4 color[];
in int blockId[];
flat in vec2 midTexcoord[];
in vec2 texcoord[];
in vec2 lmcoord[];

flat out vec4 shadowMapData;

void main() {
    //Voxelization
    //Early returns for unsupported types
    if(blockId[0] + blockId[1] + blockId[2] == 0) return;                           //Entities
    if(isWater(blockId[0]) || isWater(blockId[1]) || isWater(blockId[2])) return;   //Water

    vec3 triangleCenter = (positionPS[0] + positionPS[1] + positionPS[2]) / 3.0;
    vec3 inVoxelCoord = triangleCenter - normalWS[0] * 0.01;

    vec3 voxelPosition = playerToVoxelSpace(inVoxelCoord);

    if(voxelOutOfBounds(voxelPosition)) return;

    vec2 atlasUV = midTexcoord[0] - abs(midTexcoord[0] - texcoord[0]);
    float atlasUV_packed = packTexcoord(atlasUV);

    float blockLight = (float(lmcoord[0].x + lmcoord[1].x + lmcoord[2].x) / 3.0) / 240.0;
    vec3 hsvColor = RT_hsv(color[0].rgb);

    shadowMapData = vec4(hsvColor.xy, 0.0, float(blockId[0]) / 255.0); //W channel is 1.0 when there's no block, otherwise there is a block. Also stores the block ID

    for (int lod = 0; lod < LOD_LEVELS; lod++) {
        vec2 texturePosition = voxelToTextureSpace(uvec3(voxelPosition), lod);
        gl_Position = vec4(((texturePosition + 0.5) / shadowMapResolution) * 2.0 - 1.0, atlasUV_packed, 1.0);
        EmitVertex();
        // EndPrimitive();
    }
}
