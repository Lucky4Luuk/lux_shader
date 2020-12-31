#include "version.glsl"

#include "blockmapping.glsl"

attribute vec3 mc_Entity;
attribute vec2 mc_midTexCoord;

#include "lighting/voxelization.glsl"

     out vec2 vTexcoord;
flat out vec2 vMidTexCoord;
     out vec3 vWPos;
flat out int blockID;
     out vec4 vColor;
flat out vec3 vNormal;

void main() {
    //We set the actual vertex position to 0, as we don't need to use this.
    //The actual vertex position will be determined by the geometry shader.
    gl_Position = vec4(0.0);

    //Get the world space position of the vertex and world space normal
    vWPos = (shadowModelViewInverse * gl_ModelViewProjectionMatrix * gl_Vertex).xyz;
    vNormal = normalize(mat3(shadowModelViewInverse) * gl_NormalMatrix * gl_Normal);

    //Set up the blockID
    blockID = BackPortID(int(mc_Entity.x));

    //Texture coordinates
    vMidTexCoord = mc_midTexCoord.xy;
    vTexcoord = gl_MultiTexCoord0.xy;

    //Vertex color
    vColor = gl_Color;
}
