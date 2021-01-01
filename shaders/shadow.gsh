#include "version.glsl"

layout(triangles) in;
layout(points, max_vertices = 8) out;

uniform sampler2D tex; //I think this is the shadow buffer

#include "lighting/includes.glsl"
#include "lighting/voxelization.glsl"
#include "lighting/rt_conversion.glsl"

     in vec2 vTexcoord[];
flat in vec2 vMidTexCoord[];
     in vec3 vWPos[];
flat in int blockID[];
     in vec4 vColor[];
flat in vec3 vNormal[];

flat out vec4 data0;
flat out vec4 data1;

void main() {
    //Voxelization
    if (abs(dot(vWPos[0] - vWPos[1], vWPos[2] - vWPos[1])) < 0.001) return; //Early escape

    //Get the center of the triangle
    vec3 triCentroid = (vWPos[0] + vWPos[1] + vWPos[2]) / 3.0 - vNormal[0] / 4096.0;
	triCentroid += fract(cameraPosition); //Honestly not 100% sure why this is needed

    //Map world space triangle center to voxel space
    vec3 vPos = WorldToVoxelSpace_ShadowMap(triCentroid);
	if (OutOfVoxelBounds(vPos)) return; //Voxel is out of bounds, so no output is needed

    //Calculate variables needed to get the depth, and to fill data0 and data1
    //I don't yet really understand this, I don't get what we are storing in data0
    vec2 atlasSize = textureSize(tex, 0).xy;
	vec2 spriteSize = abs(vMidTexCoord[0] - vTexcoord[0]) * 2.0 * atlasSize;
	vec2 cornerTexCoord = vMidTexCoord[0] - abs(vMidTexCoord[0] - vTexcoord[0]);

	vec2 hs = RT_hsv(vColor[0].rgb).rg;

	data0 = vec4(log2(spriteSize.x) / 255.0, blockID[0] / 255.0, hs);
	data1 = vec4(vColor[0].rgb, 0.0);

	float depth = packTexcoord(cornerTexCoord);

    //Output vertices to control what we write to the fragment shader
    for (int LOD = 0; LOD <= 7; ++LOD) {
		vec2 coord = (VoxelToTextureSpace(uvec3(vPos), LOD) + 0.5) / shadowMapResolution;

		gl_Position = vec4(coord * 2.0 - 1.0, depth, 1.0);
		EmitVertex();
	}
}
