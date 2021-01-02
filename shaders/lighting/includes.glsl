uniform float viewWidth;
uniform float viewHeight;
uniform vec2 viewSize;
uniform float near;
uniform float far;

uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelViewInverse;
uniform mat4 gbufferModelViewInverse;

uniform vec3 cameraPosition;

uniform sampler2D shadowtex0;
uniform sampler2D shadowcolor0;
#define VOXEL_DATA_TEX shadowcolor0

uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D shadowtex1;
#define TEXTURE_ATLAS depthtex1
#define TEXTURE_ATLAS_N depthtex2
#define TEXTURE_ATLAS_S shadowtex1
