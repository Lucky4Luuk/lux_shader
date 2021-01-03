#include "version.glsl"

#include "lighting/includes.glsl"

attribute vec3 mc_Entity;
attribute vec2 mc_midTexCoord;

#include "lighting/voxelization.glsl"

out vec3 positionPS;
out vec3 normalWS;
out vec4 color;
out int blockId;
flat out vec2 midTexcoord;
out vec2 texcoord;
out vec2 lmcoord;

void main() {
    normalWS = normalize(mat3(shadowModelViewInverse) * gl_NormalMatrix * gl_Normal);
    positionPS = (shadowModelViewInverse * gl_ModelViewMatrix * gl_Vertex).xyz;
    color = gl_Color;
    blockId = int(mc_Entity.x);
    midTexcoord = mc_midTexCoord;
    texcoord = gl_MultiTexCoord0.xy;
    lmcoord = gl_MultiTexCoord1.xy;

    //Vertex position isn't needed, so we set it to [0.0, 0.0]
    gl_Position = vec4(0.0);
}
