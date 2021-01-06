#ifndef _INCLUDE_INCLUDES_GLSL_
#define _INCLUDE_INCLUDES_GLSL_

//Formats
const int RGBA32F = 0;
const int R32F = 1;
//Formats

uniform float viewWidth;
uniform float viewHeight;
uniform vec2 viewSize;
uniform float near;
uniform float far;

uniform float seed; //Supposedly random every frame
uniform int frameCounter;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;

uniform mat4 shadowModelViewInverse;
uniform mat4 shadowModelView;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform ivec2 eyeBrightness;

uniform sampler2D depthtex0; //For reprojection

uniform sampler2D shadowtex0;
uniform sampler2D shadowcolor0;
#define VOXEL_DATA_TEX shadowcolor0

uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D shadowtex1;
#define TEXTURE_ATLAS depthtex1
#define TEXTURE_ATLAS_N depthtex2
#define TEXTURE_ATLAS_S shadowtex1

uniform sampler2D colortex6;
#define GI_TEMPORAL_MAP colortex6
const bool colortex6Clear = false;
const int colortex6Format = RGBA32F;
const bool colortex6MipmapEnabled = false;

uniform sampler2D colortex0;
#define PREVIOUS_FRAME colortex0

uniform sampler2D lightmap;
uniform vec3 sunDirection;
uniform float sunAngle;

#endif
